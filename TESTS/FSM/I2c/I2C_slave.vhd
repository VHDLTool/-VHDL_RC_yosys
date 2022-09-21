-------------------------------------------------------------------------------------------------
-- Company : CNES
-- Author : AFFANE Ilyas / VIGNOLLES Morgan / LU Lichi / CHOPIER K�vin
-- Copyright : Copyright (c) CNES.
-- Licensing : This VHDL entity can be licensed to be be used in the frame of CNES contracts.
-- Ask CNES for an end-user license agreement (EULA).
-------------------------------------------------------------------------------------------------
-- Version : V2
-- Version history :
-- V1 : 2016-02-20 : AFFANE Ilyas (ENSEEIHT): Creation
-- V2 : 2017-01-04 : DAVID Mario (CNES): 
--					-synchronization problem corrected between I2C and internal communication 
--                   (from high level sinal to pulse : data_valid_reg)
--                  -correction protocol problem for ack signal
-------------------------------------------------------------------------------------------------
-- file name : I2C_slave.vhd
-- file Creation date : 2016-02-20
-- Project name : Projet NANOSAT Eyesat
-------------------------------------------------------------------------------------------------
-- Description : I2C Slave
-------------------------------------------------------------------------------------------------

library ieee;
use ieee.std_logic_1164.all;
use ieee.numeric_std.all;

entity I2C_slave is
    port (
        i_clk       : in std_logic;                     -- 66MHz Clk
        i_rst_n     : in std_logic;                     -- Reset active low
        -- I2C signals
        i_scl       : in std_logic;                     -- I2C SCL 
        b_sda       : inout std_logic;                  -- I2C SDA
        -- User interface
        i_data_w    : in std_logic_vector (7 downto 0); -- Data to send to master
        o_data_r    : out std_logic_vector (7 downto 0);-- Data Read from master
        o_read_req  : out std_logic;                    -- Flag : Master asks for data
        o_vz        : out std_logic;                    -- Flag : Data from master ready
		  i_slave_addr: in std_logic_vector (6 downto 0); -- Slave ADDR
        i_rx_mode   : in std_logic                      -- 0 : Unicast | 1 : Broadcast
    );
end I2C_slave;

architecture behavioral of I2C_slave is
    -------------------------INTERMEDIATE SIGNALS-----------------------
    signal start_done       : std_logic := '0'; -- end start detect
    signal stop_done        : std_logic := '0'; -- end stop detect
    signal en_r             : std_logic := '0'; -- Enable reading
    signal data_r           : std_logic_vector(7 downto 0) := (others => '0'); -- Data recieved from master
    signal r_done           : std_logic := '0'; -- Reading done
    signal en_master_ack    : std_logic := '0'; -- Enable master_ack
    signal continue         : std_logic := '0'; -- Continue or not of master_ack
    signal end_master_ack   : std_logic := '0'; -- Master ack done
    signal en_w             : std_logic := '0'; -- Enable writing
    signal data_w           : std_logic_vector(7 downto 0) := (others => '0'); -- Data need to send to master
    signal w_done           : std_logic := '0'; -- end of writing 
    signal en_slave_ack     : std_logic := '0'; -- Enable slave_ack
    signal end_slave_ack    : std_logic := '0'; -- Slave ack done
    signal dir_sda          : std_logic := '0'; -- Direction of sda
    signal scl_fe           : std_logic := '0'; -- Enable falling edge of scl
    signal scl_re           : std_logic := '0'; -- Enable rising edge of scl
    signal sda_int          : std_logic;
    ------------------------signal FSM----------------------------------

    type t_state is (
        idle, 
        get_address_and_cmd, 
        answer_ack_start, 
        write, 
        read, 
        read_ack_start, 
        read_stop
    );
    signal sm_state             : t_state := idle;
    signal done_flag            : std_logic := '0'; -- Flag : action (reading, writing, ack ...) was done
    signal cmd_reg              : std_logic := '0'; -- RW command from master
    signal data_valid_reg       : std_logic := '0'; -- Flag : data from master are ready on output
	 signal d_data_valid_reg	  : std_logic := '0'; -- Flag : data from master are ready on output (Registered)
	 signal re_data_valid_reg	  : std_logic := '0'; -- Flag : data from master are ready on output (Rising edge)
    signal read_req_reg         : std_logic := '0'; -- Flag : master is asking for data
    signal addr_reg             : std_logic_vector(6 downto 0) := (others => '0'); -- Address read register
    signal data_r_reg           : std_logic_vector(7 downto 0) := (others => '0'); -- Byte read from master register
    signal data_to_master_reg   : std_logic_vector(7 downto 0) := (others => '0'); -- Byte ready to be sent to master register
    ------------------------signal START/STOP/SCL DETECT----------------
    signal scl_reg              : std_logic := '0'; -- Delayed SCL (by 1 clock cycle, and by 2 clock cycles)
    signal scl_prev_reg         : std_logic := '0';
    signal sda_reg_start        : std_logic := '1'; -- Delayed SDA_START (1 clock cycle, and 2 clock cycles)
    signal sda_prev_reg_start   : std_logic := '1';
    signal sda_reg_stop         : std_logic := '1'; -- Delayed SDA_STOP (1 clock cycle, and 2 clock cycles)
    signal sda_prev_reg_stop    : std_logic := '1';
    signal start_reg            : std_logic := '0'; -- Flag : start condition
    signal stop_reg             : std_logic := '0'; -- Flag : stop condition
    signal sda_start            : std_logic := '1'; -- Start block SDA input
    signal sda_stop             : std_logic := '1'; -- Stop block SDA input
    ------------------------signal READ_DATA----------------------------
    signal enable_module_r      : std_logic := '0'; -- Enable reading block
    signal data_read_reg        : std_logic_vector(7 downto 0) := (others => '0'); -- Data read from master register
    signal bits_r_processed_reg : integer range 0 to 8 := 0; -- Counter for reading
    signal r_done_reg           : std_logic := '0'; -- Flag : Reading done
    signal sda_r                : std_logic := '1'; -- Reading block SDA input
    ------------------------signal SLAVE_ACK----------------------------- 
    signal enable_module_slave_ack  : std_logic := '0'; -- Enable Slave Ack block 
    signal end_slave_ack_reg        : std_logic := '0'; -- Flag : Ack done 
    signal sda_slave_ack_reg        : std_logic := '1'; -- Slave Ack block SDA output register
    signal sda_slave_ack            : std_logic := 'Z'; -- Slave Ack block SDA output
    ------------------------signal WRITE_DATA----------------------------
    signal enable_module_w      : std_logic := '0'; -- Enable writing block
    signal data_w_reg           : std_logic_vector(7 downto 0) := (others => '0'); -- Byte to send to master register
    signal bits_w_processed_reg : integer range 0 to 7 := 0; -- Counter for writing
    signal w_done_reg           : std_logic := '0'; -- Flag : Writing done
    signal sda_w_reg            : std_logic := '1'; -- Writing block SDA output register
    signal sda_w                : std_logic := 'Z'; -- Writing block SDA output
    ------------------------signal MASTER_ACK----------------------------
    signal enable_module_master_ack : std_logic := '0'; -- Enable master ack block
    signal continue_reg             : std_logic := '0'; -- Flag : Master will keep sending data
    signal end_master_ack_reg       : std_logic := '0'; -- Flag : Master Ack done
    signal sda_master_ack           : std_logic := '1'; -- Master Ack SDA input
    
    
    signal i_scl_int                : std_logic;

begin

    ------------------------FSM process----------------------------------

    P_FSMProcess : process (i_rst_n, i_clk) is
    begin
        if (i_rst_n = '0') then
            -- Reset FSM state
            sm_state <= idle;
            done_flag <= '0';        
            -- Reset enable signals
            en_r <= '0';
            en_slave_ack <= '0';
            en_w <= '0';
            en_master_ack <= '0';
            -- Reset User interface signals
            data_valid_reg <= '0';
            read_req_reg <= '0';
            -- Reset Addr & RW
            addr_reg <= (others=>'0');
            cmd_reg <= '0';
            -- Reset Data
            data_to_master_reg <= (others=>'0');
            data_r_reg <= (others=>'0');
            
        elsif rising_edge(i_clk) then
            -- Reset enable signals
            en_r <= '0';
            en_slave_ack <= '0';
            en_w <= '0';
            en_master_ack <= '0';

            -- User interface
            data_valid_reg <= '0';
            read_req_reg <= '0';
        
            case sm_state is

                ----------------------------------------------------
                -- Idle state : waiting for START condition
                ----------------------------------------------------
                when idle => 

                    dir_sda <= '0';

                    if start_done = '1' then
                        sm_state <= get_address_and_cmd;
                        done_flag <= '0';
                        en_r <= '1';
                    end if;

                    ----------------------------------------------------
                    -- Read first BYTE from master : 7 bits ADDR - 1 bit RW
                    ----------------------------------------------------
                when get_address_and_cmd => 
                    dir_sda <= '0';

                    if (done_flag = '0') then
 
                        if (r_done = '1') then
                            done_flag <= '1';
                        end if;
 
                    else

                        addr_reg <= data_r(7 downto 1);
                        cmd_reg <= data_r(0);

                        if (scl_fe = '1') then
                            if (i_rx_mode = '0' and ((addr_reg = i_slave_addr) or (addr_reg = "0000000"))) or (i_rx_mode = '1') then -- check req address
                                sm_state <= answer_ack_start;
                                done_flag <= '0';
                                en_slave_ack <= '1';
                                if cmd_reg = '1' then -- issue read request
                                    read_req_reg <= '1';
                                    -- soit on r�cup�re les data � envoyer au master ici (si les datas sont dispo imm�diatement apr�s un read_req)
                                    -- soit on les r�cup�re dans l'�tat suivant
                                    data_to_master_reg <= i_data_w;
                                end if;
                            else
                                sm_state <= idle;
                            end if;
                        end if;

                    end if;

                    ----------------------------------------------------
                    -- I2C acknowledge to master
                    ----------------------------------------------------
                when answer_ack_start => 
                    dir_sda <= '1';

                    if end_slave_ack = '1' then
                        if cmd_reg = '0' then
                            sm_state <= read;
                            en_r <= '1';
                        else
                            sm_state <= write;
                            en_w <= '1';
                        end if;
                    end if;

                    ----------------------------------------------------
                    -- READ: get data from master
                    ----------------------------------------------------
                when read => 
                    dir_sda <= '0';

                    if (done_flag = '0') then
 
                        if (r_done = '1') then
                            done_flag <= '1';
                        end if;
 
                    else

                        data_valid_reg <= '1';
                        data_r_reg <= data_r;

                        if scl_fe = '1' then
                            sm_state <= answer_ack_start;
                            done_flag <= '0';
                            en_slave_ack <= '1';
                        end if;

                    end if;

                    ----------------------------------------------------
                    -- WRITE: send data to master
                    ----------------------------------------------------
                when write => 
                    dir_sda <= '1';
                    data_w <= data_to_master_reg;

                    if (w_done = '1') then
                        sm_state <= read_ack_start;
                        en_master_ack <= '1';
                    end if;

                    ----------------------------------------------------
                    -- I2C read master acknowledge
                    ----------------------------------------------------
                when read_ack_start => 
                    dir_sda <= '0';

                    if (done_flag = '0') then
 
                        if end_master_ack = '1' then
                            done_flag <= '1';
                        end if;
 
                    else

                        if scl_fe = '1' then
                            if continue = '1' then
                                read_req_reg <= '1';
                                data_to_master_reg <= i_data_w;
                                sm_state <= write;
                                done_flag <= '0';
                                en_w <= '1';
                            else
                                sm_state <= read_stop;
                            end if;
                        end if;

                    end if;

                    -- wait for START or STOP to get out of this state
                when read_stop => 
                    --null;

                    -- wait for START or STOP to get out of this state
                when others => 
                    --null;
            end case;

            --------------------------------------------------------
            -- Reset state on start/stop
            --------------------------------------------------------
            if start_done = '1' then
                sm_state <= get_address_and_cmd;
                en_r <= '1';
            end if;

            if stop_done = '1' then
                sm_state <= idle;
            end if;

        end if;

    end process P_FSMProcess;
 
    ----------------------------------------------------------
    -- User interface
    ----------------------------------------------------------
    -- Master writes
	 o_vz <= re_data_valid_reg;
    o_data_r <= data_r_reg;
    -- Master reads
    o_read_req <= read_req_reg;
	 
	 ----------------------------------------------------------
    -- rising edge detection from raw_from_user_ip_wr_ok
    ----------------------------------------------------------
	 reg_wr_ok : process (i_rst_n, i_clk)is
	 begin
		  if (i_rst_n = '0') then
            d_data_valid_reg <= '0';
        elsif (rising_edge(i_clk)) then
            d_data_valid_reg <= data_valid_reg;
        end if;
	 end process reg_wr_ok;
	 
	 re_data_valid_reg <= (not d_data_valid_reg) and data_valid_reg;
 
    ------------------------SCL DETECT process---------------------------
    P_SclDetect : process (i_rst_n, i_clk) is
    begin
        if (i_rst_n = '0') then
            scl_reg <= '0';
            scl_prev_reg <= '0';
        elsif (rising_edge(i_clk)) then
            -- Delay SCL by 1 and 2 clock cycles
            scl_reg <= i_scl_int;
            scl_prev_reg <= scl_reg;
        end if;

    end process P_SclDetect;
    -- Assign the outputs of the module:
    scl_re <= scl_reg and not scl_prev_reg;
    scl_fe <= not scl_reg and scl_prev_reg;
 
    -------------------------START_DETECT process------------------------
    P_StartDetect : process (i_rst_n, i_clk) is 
    begin
    
        if (i_rst_n = '0') then
        
            sda_reg_start <= '0';
            sda_prev_reg_start <= '0';
    
        elsif rising_edge(i_clk) then

            -- Delay SDA by 1 and 2 clock cycles
            sda_reg_start <= sda_start;
            sda_prev_reg_start <= sda_reg_start;

            -- Detect I2C START condition
            start_reg <= '0';
            if scl_reg = '1' and scl_prev_reg = '1' and sda_prev_reg_start = '1' and sda_reg_start = '0' then
                start_reg <= '1';
            end if;
        end if;
    end process P_StartDetect;
    start_done <= start_reg;
 
    -------------------------STOP_DETECT process-------------------------
    P_StopDetect : process (i_rst_n, i_clk) is
 
    begin
        if (i_rst_n = '0') then
        
            sda_reg_stop <= '0';
            sda_prev_reg_stop <= '0';
    
        elsif rising_edge(i_clk) then

            -- Delay SDA by 1 and 2 clock cycles
            sda_reg_stop <= sda_stop;
            sda_prev_reg_stop <= sda_reg_stop;

            -- Detect I2C STOP condition
            stop_reg <= '0';
            if scl_prev_reg = '1' and scl_reg = '1' and sda_prev_reg_stop = '0' and sda_reg_stop = '1' then
                stop_reg <= '1';
            end if;
        end if;
    end process P_StopDetect;
    stop_done <= stop_reg;
 
    -------------------------READ_DATA process---------------------------
    P_ReadData : process (i_rst_n, i_clk) is
    begin
        if (i_rst_n = '0') then

            r_done_reg <= '0';
            data_r <= (others => '0');
            bits_r_processed_reg <= 0;
            data_read_reg <= (others => '0');
            enable_module_r <= '0';

        elsif rising_edge(i_clk) then
            if (enable_module_r = '0') then
 
                if (en_r = '1') then
                    enable_module_r <= '1';
                end if;
 
                r_done_reg <= '0';
                --data_r <= (others => '0');
                bits_r_processed_reg <= 0;
                data_read_reg <= (others => '0');
 
            elsif (enable_module_r = '1' and en_r = '1') then
 
                bits_r_processed_reg <= 0;
 
            else
 
                if scl_re = '1' then

                    data_read_reg(7 downto 0) <= data_read_reg(6 downto 0) & sda_r;

                    if bits_r_processed_reg < 8 then
                        bits_r_processed_reg <= bits_r_processed_reg + 1;
                    end if;
 
                end if;
 
                if bits_r_processed_reg = 8 then
                    enable_module_r <= '0';
                    data_r <= data_read_reg;
                    r_done_reg <= '1';
                    bits_r_processed_reg <= 0;
                end if;

            end if;

        end if;
 
    end process P_ReadData; 
    r_done <= r_done_reg;
 
    -------------------------SLAVE_ACK process---------------------------
    P_StartAck : process (i_rst_n, i_clk)
    begin
        if (i_rst_n = '0') then
 
            sda_slave_ack_reg <= '1';
            end_slave_ack_reg <= '0';
            enable_module_slave_ack <= '0';
 
        elsif (rising_edge(i_clk)) then
 
            if (enable_module_slave_ack = '0') then
 
                if (en_slave_ack = '1') then
                    enable_module_slave_ack <= '1';
                end if;
 
                end_slave_ack_reg <= '0';
                sda_slave_ack_reg <= '1';
 
            else
                sda_slave_ack_reg <= '0';
                if (scl_fe = '1') then
                    enable_module_slave_ack <= '0';
                    end_slave_ack_reg <= '1';
                end if;
 
            end if;

        end if;
    end process P_StartAck;

    sda_slave_ack <= sda_slave_ack_reg;
    end_slave_ack <= end_slave_ack_reg;

    -------------------------WRITING process-----------------------------
    P_WriteData : process (i_rst_n, i_clk) is
    begin
        if (i_rst_n = '0') then

            sda_w_reg <= '1';
            w_done_reg <= '0';
            bits_w_processed_reg <= 0;
            data_w_reg <= (others => '0');
            enable_module_w <= '0';

        elsif rising_edge(i_clk) then
            if (enable_module_w = '0') then
 
                if (en_w = '1') then
                    enable_module_w <= '1';
                end if;
 
                w_done_reg <= '0';
                sda_w_reg <= '1';
                bits_w_processed_reg <= 0;
                data_w_reg <= (others => '0');
 
            else

                sda_w_reg <= data_w_reg(7);

                if bits_w_processed_reg = 0 then
                    data_w_reg <= data_w;
                end if;

                if scl_fe = '1' then

                    if bits_w_processed_reg < 7 then
                        data_w_reg <= std_logic_vector(unsigned(data_w_reg) sll 1);
                        bits_w_processed_reg <= bits_w_processed_reg + 1;
                    elsif bits_w_processed_reg = 7 then
                        enable_module_w <= '0';
                        w_done_reg <= '1';
                        bits_w_processed_reg <= 0;
                    end if;

                end if;

            end if;

        end if;

    end process P_WriteData;
    sda_w <= sda_w_reg;
    w_done <= w_done_reg;
 
    -------------------------MASTER_ACK process--------------------------
    P_ReadAck : process (i_rst_n, i_clk)
    begin
        if (i_rst_n = '0') then
 
            end_master_ack_reg <= '0';
            continue_reg <= '0';
            enable_module_master_ack <= '0';
 
        elsif (rising_edge(i_clk)) then
 
            if (enable_module_master_ack = '0') then
 
                if (en_master_ack = '1') then
                    enable_module_master_ack <= '1';
                end if;
 
                end_master_ack_reg <= '0';
 
            else

                if (scl_re = '1') then
 
                    enable_module_master_ack <= '0';
                    end_master_ack_reg <= '1';
 
                    if (sda_master_ack = '1') then
                        continue_reg <= '0';
                    else
                        continue_reg <= '1';
                    end if;

                end if;

            end if;

        end if;
    end process P_ReadAck;

    continue <= continue_reg;
    end_master_ack <= end_master_ack_reg;

    ----------------------OUTPUT SELECTION------------------------
    sda_int <= sda_w when (enable_module_w = '1' and enable_module_slave_ack = '0')
               else sda_slave_ack when (enable_module_w = '0' and enable_module_slave_ack = '1')
               else '1'; 
					
    b_sda <= '0' when (dir_sda = '1' and sda_int = '0')
             else 'Z';

    sda_start <= dir_sda when b_sda = '0' else '1';

    sda_r <= dir_sda when b_sda = '0' else '1';
    
    sda_master_ack <= dir_sda when b_sda = '0' else '1';

	 sda_stop <= dir_sda when b_sda = '0' else sda_stop;
	
	 i_scl_int <= '0' when i_scl = '0' else '1';
                	

end architecture behavioral;