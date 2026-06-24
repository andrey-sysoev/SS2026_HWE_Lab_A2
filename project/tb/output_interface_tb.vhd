-- Testbench for output_interface.vhd.
--
-- Testbench checks:
--
--   1. Reset clears the display and LED.
--   2. The block ignores z and class_result while done = '0'.
--   3. done = '1' stores z and class_result on a rising clock edge.
--   4. class_led follows the stored class_result.
--   5. The seven-segment display shows the stored absolute score.
--   6. The sign is not shown on the seven-segment display.
--   7. The result stays visible after done goes back to '0'.

entity output_interface_tb is
end entity;

architecture bench of output_interface_tb is

    component output_interface
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
    end component;

    signal CLK_TB          : bit := '0';
    signal RESET_TB        : bit := '0';
    signal DONE_TB         : bit := '0';
    signal Z_TB            : integer range -128 to 127 := 0;
    signal CLASS_RESULT_TB : bit := '0';

    signal CLASS_LED_TB    : bit;
    signal SEG_TB          : bit_vector(6 downto 0);
    signal AN_TB           : bit_vector(7 downto 0);

    -- Return the absolute value of the score.
    -- The output interface displays the magnitude of z.
    function expected_abs(score : integer) return integer is
        variable abs_score : integer;
    begin
        if score < 0 then
            abs_score := 0 - score;
        else
            abs_score := score;
        end if;

        return abs_score;
    end function;

    -- Convert one decimal digit into the active-low seven-segment pattern.
    -- This is the expected display encoding used by the lab files.
    function digit_to_seg(digit : integer) return bit_vector is
        variable seg_value : bit_vector(6 downto 0);
    begin
        case digit is
            when 0 =>
                seg_value := "0000001";
            when 1 =>
                seg_value := "1001111";
            when 2 =>
                seg_value := "0010010";
            when 3 =>
                seg_value := "0000110";
            when 4 =>
                seg_value := "1001100";
            when 5 =>
                seg_value := "0100100";
            when 6 =>
                seg_value := "0100000";
            when 7 =>
                seg_value := "0001111";
            when 8 =>
                seg_value := "0000000";
            when 9 =>
                seg_value := "0000100";
            when others =>
                seg_value := "1111111";
        end case;

        return seg_value;
    end function;

    -- Return the expected SEG value for one display position.
    -- digit_position = 0 checks ones.
    -- digit_position = 1 checks tens or blank.
    -- digit_position = 2 checks hundreds or blank.
    function expected_seg(score : integer; digit_position : integer) return bit_vector is
        variable abs_score : integer;
        variable digit     : integer;
        variable seg_value : bit_vector(6 downto 0);
    begin
        abs_score := expected_abs(score);

        case digit_position is

            -- Rightmost digit: ones. This digit is always shown.
            when 0 =>
                digit := abs_score mod 10;
                seg_value := digit_to_seg(digit);

            -- Second digit: tens. It is blank for one-digit scores.
            when 1 =>
                if abs_score >= 10 then
                    digit := (abs_score / 10) mod 10;
                    seg_value := digit_to_seg(digit);
                else
                    seg_value := "1111111";
                end if;

            -- Third digit: hundreds. It is blank for scores below 100.
            when others =>
                if abs_score >= 100 then
                    digit := abs_score / 100;
                    seg_value := digit_to_seg(digit);
                else
                    seg_value := "1111111";
                end if;

        end case;

        return seg_value;
    end function;

    -- Return the expected active-low anode pattern for one display position.
    -- Only the three rightmost digits are used by output_interface.vhd.
    function expected_an(digit_position : integer) return bit_vector is
        variable an_value : bit_vector(7 downto 0);
    begin
        case digit_position is
            when 0 =>
                an_value := "11111110";
            when 1 =>
                an_value := "11111101";
            when others =>
                an_value := "11111011";
        end case;

        return an_value;
    end function;

begin

    DUT: output_interface
        port map (
            clk          => CLK_TB,
            reset        => RESET_TB,
            done         => DONE_TB,
            z            => Z_TB,
            class_result => CLASS_RESULT_TB,
            class_led    => CLASS_LED_TB,
            SEG          => SEG_TB,
            AN           => AN_TB
        );

    clock_process: process
    begin
        CLK_TB <= '0';
        wait for 5 ns;

        CLK_TB <= '1';
        wait for 5 ns;
    end process;

    stimulus: process

        procedure check_blank is
        begin
            assert CLASS_LED_TB = '0'
                report "Blank check failed: class_led must be 0"
                severity failure;

            assert SEG_TB = "1111111"
                report "Blank check failed: SEG must be blank"
                severity failure;

            assert AN_TB = "11111111"
                report "Blank check failed: AN must disable all digits"
                severity failure;
        end procedure;

        -- Apply reset and check the blank state.
        -- It is used before display tests so every case starts cleanly.
        procedure reset_display is
        begin
            RESET_TB <= '1';
            DONE_TB <= '0';
            Z_TB <= 0;
            CLASS_RESULT_TB <= '0';
            wait for 12 ns;

            check_blank;

            RESET_TB <= '0';
            wait for 8 ns;
        end procedure;

        -- Present a valid result to the output interface.
        -- This checks the same done pulse used by the control unit.
        procedure store_result(score : integer; class_value : bit) is
        begin
            Z_TB <= score;
            CLASS_RESULT_TB <= class_value;
            DONE_TB <= '1';

            wait until CLK_TB'event and CLK_TB = '1';
            wait for 1 ns;

            DONE_TB <= '0';
            wait for 1 ns;
        end procedure;

        -- Change inputs without a valid done pulse.
        -- This checks that unconfirmed values do not change the output.
        procedure change_without_done(score : integer; class_value : bit) is
        begin
            Z_TB <= score;
            CLASS_RESULT_TB <= class_value;
            DONE_TB <= '0';

            wait until CLK_TB'event and CLK_TB = '1';
            wait for 1 ns;
        end procedure;

        -- Wait until the display should move to the next multiplexed digit.
        -- This checks each visible digit position of the score.
        procedure wait_next_digit is
        begin
            wait for 500050 ns;
            wait for 1 ns;
        end procedure;

        -- Check one visible display position.
        -- This keeps LED, anode, segment, and sign checks together.
        procedure check_digit(score : integer;
                              class_value : bit;
                              digit_position : integer) is
        begin
            -- The LED must show the stored class_result value.
            assert CLASS_LED_TB = class_value
                report "Display check failed: class_led does not match stored class_result"
                severity failure;

            -- The selected seven-segment digit must match the checked position.
            assert AN_TB = expected_an(digit_position)
                report "Display check failed: wrong active anode"
                severity failure;

            -- The segment pattern must match the expected digit or blank.
            assert SEG_TB = expected_seg(score, digit_position)
                report "Display check failed: wrong seven-segment digit"
                severity failure;

            -- Negative scores are shown by magnitude only, without a minus sign.
            assert SEG_TB /= "1111110"
                report "Display check failed: seven-segment display must not show minus sign"
                severity failure;
        end procedure;

        -- Check the complete three-digit display for one stored result.
        -- This verifies ones, tens, and hundreds for the same captured score.
        procedure check_full_display(score : integer; class_value : bit) is
        begin
            reset_display;
            store_result(score, class_value);

            -- Rightmost digit: ones.
            check_digit(score, class_value, 0);

            -- Second digit: tens or blank.
            wait_next_digit;
            check_digit(score, class_value, 1);

            -- Third digit: hundreds or blank.
            wait_next_digit;
            check_digit(score, class_value, 2);
        end procedure;

    begin

        -- Shape/constraint checks for display outputs.
        -- These checks catch accidental changes to the public output widths.
        assert SEG_TB'length = 7
            report "SEG_TB must contain exactly seven segment bits"
            severity failure;

        assert AN_TB'length = 8
            report "AN_TB must contain exactly eight anode bits"
            severity failure;

        -- RESET TEST
        --
        -- reset = '1' should clear stored result information.
        -- Therefore:
        --   class_led should be 0
        --   SEG should be blank
        --   AN should disable all digits
        -- This checks that reset removes any previously valid display result.
        reset_display;

        -- NO-RESULT TEST
        --
        -- Before done = '1', changing z and class_result should not create
        -- a valid display output.
        -- This checks that the output interface waits for a valid result.
        Z_TB <= 127;
        CLASS_RESULT_TB <= '1';
        DONE_TB <= '0';
        wait until CLK_TB'event and CLK_TB = '1';
        wait for 1 ns;
        check_blank;

        Z_TB <= -128;
        CLASS_RESULT_TB <= '0';
        wait until CLK_TB'event and CLK_TB = '1';
        wait for 1 ns;
        check_blank;

        -- HOLD AND OVERWRITE TEST
        --
        -- Store one valid result, change the inputs while done = '0',
        -- then store a second valid result.
        -- This checks that old valid results are held and new valid results replace them.
        reset_display;
        store_result(12, '1');
        check_digit(12, '1', 0);

        change_without_done(-4, '0');
        check_digit(12, '1', 0);

        store_result(-4, '0');
        check_digit(-4, '0', 0);

        -- DISPLAY FORMAT TESTS
        --
        -- These cases cover zero, one-digit, two-digit, three-digit,
        -- positive, negative, and boundary score values.
        -- This checks that the seven-segment display shows abs(z), not signed z.
        check_full_display(0, '1');
        check_full_display(1, '1');
        check_full_display(-1, '0');
        check_full_display(4, '1');
        check_full_display(-4, '0');
        check_full_display(9, '1');
        check_full_display(-9, '0');
        check_full_display(10, '1');
        check_full_display(-10, '0');
        check_full_display(12, '1');
        check_full_display(-12, '0');
        check_full_display(99, '1');
        check_full_display(-99, '0');
        check_full_display(100, '1');
        check_full_display(-100, '0');
        check_full_display(127, '1');
        check_full_display(-128, '0');

        -- LED PASS-THROUGH TEST
        --
        -- The output interface must display the class_result it receives.
        -- It must not calculate class_led from z.
        -- This checks that LED output is controlled by class_result only.
        check_full_display(-5, '1');
        check_full_display(5, '0');

        -- RESET AFTER RESULT TEST
        --
        -- reset = '1' should clear the stored result again.
        -- This checks reset priority after the block has displayed data.
        RESET_TB <= '1';
        wait for 1 ns;
        check_blank;

        wait;

    end process;

end architecture;
