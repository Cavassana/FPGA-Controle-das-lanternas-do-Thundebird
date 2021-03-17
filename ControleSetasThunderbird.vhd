library IEEE; -- EP2C5T144 EM FPGA MINI BOARD 50Mhz
use IEEE.STD_LOGIC_1164.ALL;
use IEEE.numeric_std.ALL;
use IEEE.std_logic_unsigned.ALL;

ENTITY ControleSetasThunderbird IS -- 
    PORT (	clk		: IN STD_LOGIC; -- relogio				 
				alavanca	: IN STD_LOGIC_VECTOR(1 DOWNTO 0); -- decodificao na linha abaixo:
-- posicao da alavanca  => neutro => alavanca="00" | seta_dir => alavanca="01" | seta_esq => alavanca="10" | emergencia => alavanca="11" |
			lanterna_esq : OUT STD_LOGIC_VECTOR(2 DOWNTO 0);	-- saida lanterna esquerda
			lanterna_dir : OUT STD_LOGIC_VECTOR(2 DOWNTO 0)); -- saida lanterna direita
END ControleSetasThunderbird;

ARCHITECTURE testeControleSetasThunderbird OF ControleSetasThunderbird IS 
-- 				   "000"	  "100"		"110"	   "111"	  "001"	 	  "011"
TYPE st_lamp IS (estagio_0, estagio_1, estagio_2, estagio_3, estagio_4, estagio_5); -- define variavel para o lanterna esquerda
SIGNAL estado_lanterna_dir : st_lamp; -- estado lampadas direita
SIGNAL estado_lanterna_esq : st_lamp; -- estado lampadas esquerdo
CONSTANT contador_max : natural := 50000000; -- 50Mhz
SIGNAL op : STD_LOGIC;

BEGIN 

PROCESS(clk) -- sensível ao relogio
	VARIABLE aContagem: natural range 0 to contador_max;
BEGIN
	IF (clk'EVENT AND clk ='1' AND aContagem<(contador_max/2)-1) THEN 
		op <='1';
		aContagem := aContagem+1;
	ELSIF (clk'EVENT AND clk ='1' AND aContagem<contador_max-1) THEN
		op <='0';
		aContagem := aContagem+1;
	ELSIF (clk'EVENT AND clk ='1' AND aContagem<contador_max) THEN 
		op <='1';
		aContagem := 0;
	END IF;
END PROCESS;

configura_estado:PROCESS (op, alavanca) -- sensivel a ck e a alavanca
BEGIN
	IF alavanca = "00" THEN -- estado neutro
		estado_lanterna_esq <= estagio_0; 							
		estado_lanterna_dir <= estagio_0;
	ELSIF (op'EVENT AND op = '1') THEN 								-- define ck como borda de subida
		IF alavanca = "11" THEN 									-- emergencia => alavanca="11" 
			estado_lanterna_esq <= estagio_0; 							
			estado_lanterna_dir <= estagio_0;
			CASE estado_lanterna_esq IS
				WHEN estagio_0 => estado_lanterna_esq <= estagio_3;	
				WHEN estagio_3 => estado_lanterna_esq <= estagio_0;
				WHEN OTHERS => NULL;
			END CASE;	
			CASE estado_lanterna_dir IS
				WHEN estagio_0 => estado_lanterna_dir <= estagio_3;	
				WHEN estagio_3 => estado_lanterna_dir <= estagio_0;
				WHEN OTHERS => NULL;
			END CASE;	
		ELSIF alavanca = "01" THEN 									-- seta_dir => alavanca="01"
			estado_lanterna_esq <= estagio_0;						-- trava a lanterna esquerda
			CASE estado_lanterna_dir IS 							-- define os proximos estagios
				WHEN estagio_0 => estado_lanterna_dir <= estagio_1;	-- "000" -> "100" 
				WHEN estagio_1 => estado_lanterna_dir <= estagio_2;	-- "100" -> "110"					
				WHEN estagio_2 => estado_lanterna_dir <= estagio_3;	-- "110" -> "111"							-
				WHEN estagio_3 => estado_lanterna_dir <= estagio_0;	-- "111" -> "000"
				WHEN OTHERS => NULL;			
			END CASE; 
		ELSIF alavanca = "10" THEN 									-- seta_esq => alavanca="10" 
			estado_lanterna_dir <= estagio_0;						-- trava a lanterna esquerda
			CASE estado_lanterna_esq IS 							-- define os proximos estagios
				WHEN estagio_0 => estado_lanterna_esq <= estagio_4;	-- "000" -> "001" 
				WHEN estagio_4 => estado_lanterna_esq <= estagio_5;	-- "001" -> "011"					
				WHEN estagio_5 => estado_lanterna_esq <= estagio_3;	-- "011" -> "111"
				WHEN estagio_3 => estado_lanterna_esq <= estagio_0;	-- "111" -> "000"	
				WHEN OTHERS => NULL;	
			END CASE; 
		END IF;
	END IF;
END PROCESS configura_estado;
	
WITH estado_lanterna_dir SELECT	
		lanterna_dir <=	"000" WHEN estagio_0, 			-- "000"
								"100" WHEN estagio_1, 		 	-- "100"
								"110" WHEN estagio_2, 			-- "110"
								"111" WHEN estagio_3, 			-- "111"
								"001" WHEN estagio_4, 			-- "001"
								"011" WHEN estagio_5; 			-- "011"
WITH estado_lanterna_esq SELECT	
		lanterna_esq <=	"000" WHEN estagio_0, 			-- "000"
								"100" WHEN estagio_1, 		 	-- "100"
								"110" WHEN estagio_2, 			-- "110"
								"111" WHEN estagio_3, 			-- "111"
								"001" WHEN estagio_4, 			-- "001"
								"011" WHEN estagio_5; 			-- "011"	
END testeControleSetasThunderbird;
		