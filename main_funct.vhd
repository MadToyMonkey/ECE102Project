----------------------------------------------------------------------------------
-- Company: 
-- Engineer: 
-- 
-- Create Date:    16:01:44 04/21/2018 
-- Design Name: 
-- Module Name:    main_funct - Behavioral 
-- Project Name: 
-- Target Devices: 
-- Tool versions: 
-- Description: 
--
-- Dependencies: 
--
-- Revision: 
-- Revision 0.01 - File Created
-- Additional Comments: 
--
----------------------------------------------------------------------------------
library IEEE;
use IEEE.STD_LOGIC_1164.ALL;

-- Uncomment the following library declaration if using
-- arithmetic functions with Signed or Unsigned values
--use IEEE.NUMERIC_STD.ALL;

-- Uncomment the following library declaration if instantiating
-- any Xilinx primitives in this code.
--library UNISIM;
--use UNISIM.VComponents.all;

entity main_funct is
    Port ( clk : in  STD_LOGIC;
           reset : in  STD_LOGIC;
           LCD_E : out  STD_LOGIC;
           LCD_RS : out  STD_LOGIC;
           LCD_RW : out  STD_LOGIC;
           SF_D : out  STD_LOGIC_VECTOR (3 downto 0));
end main_funct;

architecture Behavioral of main_funct is
		
		type states is ( start, function_set, entry_set, set_d, clear_display, set_d1, waiting1, waiting,def_address,E,C,finish,finish2);
		signal next_st : states:=start;
		signal data_lcd : std_logic_vector(7 downto 0 );
		signal en_tx: std_logic:='0';
		signal init_done : std_logic :='0';
		signal enable : std_logic:='0';
		signal selct: std_logic;
		signal SF_D0 : std_logic_vector(3 downto 0);
		signal SF_D1 : std_logic_vector(3 downto 0);
		signal LCD_E0 : std_logic;
		signal LCD_E1 : std_logic;
		signal c1: integer range 0 to 2000:=0;
		signal count82: integer range 0 to 82000:=0;
		signal waitCount: integer range 0 to 10000000:=0;
		
		component power_on_initialisation
				port (clk : in STD_LOGIC;
						reset : in STD_LOGIC;
						LCD_E0 : out STD_LOGIC;
						SF_D0 : out std_logic_vector( 3 downto 0);
						init_done : out std_logic;
						enable : in std_logic);
		end component;

		component transferring_data
				port ( reset : in std_logic;
						clk   : in std_logic;
						en_tx: in std_logic;
						SF_D1 : out std_logic_vector ( 3 downto 0);
						LCD_E1 : out std_logic;
						c1 : out integer;
						CONTENT : in std_logic_vector ( 7 downto 0));
		end component;
		
begin
LCD_RW <= '0';
	  
		process(reset,clk)
			begin
					if(reset = '1') then
							next_st <= function_set;
						elsif(clk'event and clk = '1') then
					
						case next_st is

						  when start =>
										enable <= '1';
										en_tx <= '0';
										selct <= '1';
										LCD_RS <= '1';
										data_lcd <= "00000000";
								if(init_done = '1') then
										next_st <= function_set;
										else next_st <= start;
								end if;

						when function_set =>          --- configuring the display
									enable <='0';
									LCD_RS <= '0';
									selct <= '0';
									data_lcd <= "00101000";     -- command 0X28
									en_tx <= '1';
						if( c1 =2000) then
									next_st <= entry_set;
							else next_st <= function_set;
						end if;

						when entry_set =>        -- set the display
								enable <='0';
								LCD_RS <= '0';
								data_lcd <= "00000110";    -- command 0X06
								en_tx <= '1';
								selct <= '0';
							if ( c1 = 2000) then
										next_st <= set_d;
								 else next_st <= entry_set;
							end if;

						when set_d =>                 -- turn the display on
								enable <='0';
								LCD_RS <= '0';
								data_lcd <= "00001100";     -- command 0X0C
								en_tx <= '1';
								selct <= '0';
							if ( c1 = 2000) then
									next_st <= clear_display;
								else next_st <= set_d;
							end if;

						when clear_display =>      -- clear display
								count82<= 0;
								enable <='0';
								LCD_RS <= '0';
								data_lcd <= "00000001";     -- command 0X01
								en_tx <= '1';
								selct <= '0';
						if( c1 = 2000) then 
								next_st <= waiting;
							else next_st <= clear_display;
						end if;

					when waiting =>            -- wait for 1.64 ms or 82000 cycles
								enable <='0';
								en_tx <= '0';
								selct <= '0';
								LCD_RS <= '1';
								data_lcd <= "00000000";
					if( count82 = 82000) then        
								count82 <= 0;
								next_st <= def_address;
							else next_st <= waiting;
								count82<= count82 + 1;
					end if;


				when def_address=>            -- character display address
						enable <='0';
						LCD_RS <= '0';
						data_lcd <= "10000000";     -- Display at the top left corner
						
						en_tx <= '1';
						selct <= '0';
					if( c1 = 2000) then
								next_st <= E;
						else next_st <= def_address;
					end if;

				when E =>
							enable <= '1';
							lcd_rs <= '1';
							data_lcd <= "01000101";
							en_tx <= '1';
						if(c1 = 2000) then
							next_st <= finish;
						else
							next_st <= E;
						end if;

				when C =>
							enable <= '1';
							lcd_rs <= '1';
							data_lcd <= "01000011";
							en_tx <= '1';
						if(c1 = 2000) then
							next_st <= finish2;
						else
							next_st <= C;
						end if;


				when finish =>
							enable <='0';
							en_tx <= '0';
							selct <= '0';
							LCD_RS <= '1';
							LCD_RW<='0';
							data_lcd <= "11111110";
							if(c1 = 2000) then
								next_st <= C;
							else
								next_st <= finish;
							end if;
							
				when finish2 =>
							enable <='0';
							en_tx <= '0';
							selct <= '0';
							LCD_RS <= '1';
							LCD_RW<='0';
							data_lcd <= "11111110";
							if(c1 = 2000) then
								next_st <= waiting1;
							else
								next_st <= finish;
							end if;
							
					when waiting1 =>            -- wait for 1.64 ms or 82000 cycles
								enable <='0';
								en_tx <= '0';
								selct <= '0';
								LCD_RS <= '1';
								data_lcd <= "00000000";
							if( waitCount = 10000000) then        
										waitCount <= 0;
										next_st <= set_d1;
									else next_st <= waiting1;
										waitCount<= waitCount + 1;
							end if;
					
					when set_d1 =>                 -- turn the display on and shifts
							enable <='0';
							LCD_RS <= '0';
							--data_lcd <= "00001100";     -- command 0X0C
							data_lcd <= "00011000";     -- command 0X11
							en_tx <= '1';
							selct <= '0';
							if ( c1 = 2000) then
									next_st <= def_address;
								else next_st <= set_d1;
							end if;					
					

		end case;
	end if;
end process;

with selct select 
	SF_D <= SF_D1 when '0',
	        SF_D0 when others;
			  
with selct select
   LCD_E <= LCD_E1 when '0',
			   LCD_E0 when others;
				
-- components port mapping

 pwr_init:power_on_initialisation port map (clk=> clk,
												reset => reset,
												SF_D0 => SF_D0,
												LCD_E0 => LCD_E0,
												init_done => init_done,
												enable => enable);
												
data_trans:transferring_data port map (clk => clk,
												  reset=> reset,
												  SF_D1 => SF_D1,
												  LCD_E1 => LCD_E1,
												  en_tx => en_tx,
												  c1 => c1,
												  CONTENT => data_lcd);




end Behavioral;

