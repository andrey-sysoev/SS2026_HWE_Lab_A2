-- This block displays the classifier result.
--
-- Inputs:
--   done         : tells this block that z and class_result are ready
--   z            : score from classifier.vhd
--   class_result : class from classifier.vhd
--
-- Outputs:
--   class_led : LED output for the class
--   SEG       : seven-segment cathode signals
--   AN        : seven-segment anode signals


entity output_interface is
    port (
        clk          : in  bit;
        reset        : in  bit;
        done         : in  bit;
        z            : in  integer range -128 to 127;
        class_result : in  bit;

        class_led    : out bit;
        SEG          : out bit_vector(6 downto 0);
        AN           : out bit_vector(7 downto 0)
    );
end entity;

architecture behavior of output_interface is

    -- Stored output values.
    -- They are updated when done = '1'.
    -- This keeps the result visible after the control unit returns to IDLE.
    signal score_reg     : integer range -128 to 127 := 0;
    signal class_led_reg : bit := '0';
    signal result_valid  : bit := '0';

    -- Display multiplexing signals.
    --
    -- digit_select = 0: rightmost digit, ones
    -- digit_select = 1: second digit, tens
    -- digit_select = 2: third digit, hundreds
    signal display_count : integer range 0 to 50000 := 0;
    signal digit_select  : integer range 0 to 2 := 0;

    -- Score display helper signals.
    -- The absolute score is split into three decimal digits.
    signal ones_digit     : integer range 0 to 9 := 0;
    signal tens_digit     : integer range 0 to 9 := 0;
    signal hundreds_digit : integer range 0 to 1 := 0;

begin

    -- Store the newest classifier result.
    Result_Register_Process: process(clk, reset)
    begin
        if reset = '1' then
            score_reg <= 0;
            class_led_reg <= '0';
            result_valid <= '0';

        elsif clk'event and clk = '1' then

            if done = '1' then
                score_reg <= z;
                class_led_reg <= class_result;
                result_valid <= '1';
            end if;

        end if;
    end process;

    -- Connect stored class value to the LED output.
    class_led <= class_led_reg;

    -- Create a slower display select signal from the board clock.
    Display_Clock_Process: process(clk, reset)
    begin
        if reset = '1' then
            display_count <= 0;
            digit_select <= 0;

        elsif clk'event and clk = '1' then

            if display_count = 50000 then
                display_count <= 0;

                case digit_select is
                    when 0 =>
                        digit_select <= 1;
                    when 1 =>
                        digit_select <= 2;
                    when others =>
                        digit_select <= 0;
                end case;

            else
                display_count <= display_count + 1;
            end if;

        end if;
    end process;

    -- Convert the stored score into:
    --   hundreds_digit : hundreds digit of the absolute score
    --   tens_digit     : tens digit of the absolute score
    --   ones_digit     : ones digit of the absolute score
    --
    -- The LED shows the class result. Since the classifier uses
    -- z >= 0 for class 1 and z < 0 for class 0, the LED also tells
    -- whether the score was negative or not.
    --
    -- The seven-segment display shows the absolute score value:
    --   z =  127 -> 127
    --   z = -128 -> 128
    --   z =   12 -> 12
    --   z =   -4 -> 4
    --   z =    0 -> 0
    Score_Preparation_Process: process(score_reg)
        variable abs_score : integer range 0 to 128;
    begin
        if score_reg < 0 then
            abs_score := 0 - score_reg;
        else
            abs_score := score_reg;
        end if;

        ones_digit <= abs_score mod 10;
        tens_digit <= (abs_score / 10) mod 10;
        hundreds_digit <= abs_score / 100;
    end process;

    -- Seven-segment display process.
    --
    -- Segment mapping:
    --   SEG(6) = A
    --   SEG(5) = B
    --   SEG(4) = C
    --   SEG(3) = D
    --   SEG(2) = E
    --   SEG(1) = F
    --   SEG(0) = G
    --
    -- Active-low patterns:
    --   "0000001" = 0
    --   "1001111" = 1
    --   "0010010" = 2
    --   "0000110" = 3
    --   "1001100" = 4
    --   "0100100" = 5
    --   "0100000" = 6
    --   "0001111" = 7
    --   "0000000" = 8
    --   "0000100" = 9
    --   "1111111" = blank
    Display_Process: process(reset, result_valid, digit_select,
                             ones_digit, tens_digit, hundreds_digit)

        variable display_digit : integer range 0 to 9;
        variable show_digit    : bit;

    begin
        if reset = '1' then
            SEG <= "1111111";
            AN <= "11111111";

        elsif result_valid = '0' then
            SEG <= "1111111";
            AN <= "11111111";

        else

            display_digit := 0;
            show_digit := '0';

            case digit_select is

                -- Rightmost digit: ones.
                when 0 =>
                    AN <= "11111110";
                    display_digit := ones_digit;
                    show_digit := '1';

                -- Second digit: tens.
                when 1 =>
                    AN <= "11111101";

                    if hundreds_digit /= 0 or tens_digit /= 0 then
                        display_digit := tens_digit;
                        show_digit := '1';
                    else
                        show_digit := '0';
                    end if;

                -- Third digit: hundreds.
                when others =>
                    AN <= "11111011";

                    if hundreds_digit /= 0 then
                        display_digit := hundreds_digit;
                        show_digit := '1';
                    else
                        show_digit := '0';
                    end if;

            end case;

            if show_digit = '1' then

                case display_digit is
                    when 0 =>
                        SEG <= "0000001";
                    when 1 =>
                        SEG <= "1001111";
                    when 2 =>
                        SEG <= "0010010";
                    when 3 =>
                        SEG <= "0000110";
                    when 4 =>
                        SEG <= "1001100";
                    when 5 =>
                        SEG <= "0100100";
                    when 6 =>
                        SEG <= "0100000";
                    when 7 =>
                        SEG <= "0001111";
                    when 8 =>
                        SEG <= "0000000";
                    when 9 =>
                        SEG <= "0000100";
                    when others =>
                        SEG <= "1111111";
                end case;

            else
                SEG <= "1111111";
            end if;

        end if;
    end process;

end architecture;
