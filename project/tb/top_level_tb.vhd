-- Testbench for top_level.vhd.
--
-- This is a board-level integration test.
--
-- It drives the public top-level inputs:
--   CLK, RESET, START, SW
--
-- It checks the public top-level outputs:
--   CLASS_LED, SEG, AN


entity top_level_tb is
end entity;

architecture bench of top_level_tb is

    component top_level
        port (
            CLK       : in  bit;
            RESET     : in  bit;
            START     : in  bit;
            SW        : in  bit_vector(3 downto 0);

            CLASS_LED : out bit;
            SEG       : out bit_vector(6 downto 0);
            AN        : out bit_vector(7 downto 0)
        );
    end component;

    signal CLK_TB       : bit := '0';
    signal RESET_TB     : bit := '0';
    signal START_TB     : bit := '0';
    signal SW_TB        : bit_vector(3 downto 0) := "0000";

    signal CLASS_LED_TB : bit;
    signal SEG_TB       : bit_vector(6 downto 0);
    signal AN_TB        : bit_vector(7 downto 0);

    -- Return '1' when the seven-segment output is one of the decimal digit
    -- patterns used by output_interface.vhd. Blank is not a valid result here.
    function is_digit_pattern(value : bit_vector(6 downto 0)) return bit is
    begin
        case value is
            when "0000001" =>
                return '1';
            when "1001111" =>
                return '1';
            when "0010010" =>
                return '1';
            when "0000110" =>
                return '1';
            when "1001100" =>
                return '1';
            when "0100100" =>
                return '1';
            when "0100000" =>
                return '1';
            when "0001111" =>
                return '1';
            when "0000000" =>
                return '1';
            when "0000100" =>
                return '1';
            when others =>
                return '0';
        end case;
    end function;

    -- Return '1' when one of the three score-display digits is enabled.
    function is_used_anode(value : bit_vector(7 downto 0)) return bit is
    begin
        case value is
            when "11111110" =>
                return '1';
            when "11111101" =>
                return '1';
            when "11111011" =>
                return '1';
            when others =>
                return '0';
        end case;
    end function;

begin

    DUT: top_level
        port map (
            CLK       => CLK_TB,
            RESET     => RESET_TB,
            START     => START_TB,
            SW        => SW_TB,
            CLASS_LED => CLASS_LED_TB,
            SEG       => SEG_TB,
            AN        => AN_TB
        );

    clock_process: process
    begin
        CLK_TB <= '0';
        wait for 5 ns;

        CLK_TB <= '1';
        wait for 5 ns;
    end process;

    stimulus: process
        variable held_led : bit;
        variable held_seg : bit_vector(6 downto 0);
        variable held_an  : bit_vector(7 downto 0);

        procedure check_blank is
        begin
            assert CLASS_LED_TB = '0'
                report "Blank check failed: CLASS_LED should be 0"
                severity failure;

            assert SEG_TB = "1111111"
                report "Blank check failed: SEG should be blank"
                severity failure;

            assert AN_TB = "11111111"
                report "Blank check failed: AN should disable all digits"
                severity failure;
        end procedure;

        procedure check_visible_result is
        begin
            assert is_used_anode(AN_TB) = '1'
                report "Visible result failed: AN is not a used display digit"
                severity failure;

            assert is_digit_pattern(SEG_TB) = '1'
                report "Visible result failed: SEG is not a decimal digit pattern"
                severity failure;
        end procedure;

        procedure reset_top is
        begin
            RESET_TB <= '1';
            START_TB <= '0';
            wait for 12 ns;

            check_blank;

            RESET_TB <= '0';
            wait for 8 ns;
        end procedure;

        procedure pulse_start_and_wait is
        begin
            START_TB <= '1';
            wait for 10 ns;

            START_TB <= '0';
            wait for 40 ns;
        end procedure;

        procedure run_top_case(sw_value : bit_vector(3 downto 0)) is
        begin
            reset_top;

            SW_TB <= sw_value;
            wait for 1 ns;

            -- Changing switches alone must not create a valid result.
            check_blank;

            pulse_start_and_wait;
            check_visible_result;
        end procedure;

    begin

        -- Reset must clear every block through the top-level reset input.
        reset_top;

        -- With START low, switch changes must not make the output interface
        -- display a result.
        SW_TB <= "0001";
        wait for 10 ns;
        check_blank;

        SW_TB <= "1010";
        wait for 10 ns;
        check_blank;

        SW_TB <= "1111";
        wait for 10 ns;
        check_blank;

        -- For every possible switch pattern, START must cause the integrated
        -- control_unit -> classifier -> output_interface path to produce a
        -- visible board-level result. If any real classifier score is outside
        -- its -128 to 127 range, simulation fails inside the DUT.
        run_top_case("0000");
        run_top_case("0001");
        run_top_case("0010");
        run_top_case("0011");
        run_top_case("0100");
        run_top_case("0101");
        run_top_case("0110");
        run_top_case("0111");
        run_top_case("1000");
        run_top_case("1001");
        run_top_case("1010");
        run_top_case("1011");
        run_top_case("1100");
        run_top_case("1101");
        run_top_case("1110");
        run_top_case("1111");

        -- After a displayed result, switch changes without START must not
        -- change the visible board outputs.
        held_led := CLASS_LED_TB;
        held_seg := SEG_TB;
        held_an  := AN_TB;

        SW_TB <= "0000";
        wait for 30 ns;

        assert CLASS_LED_TB = held_led
            report "Hold failed: CLASS_LED changed without START"
            severity failure;

        assert SEG_TB = held_seg
            report "Hold failed: SEG changed without START"
            severity failure;

        assert AN_TB = held_an
            report "Hold failed: AN changed without START"
            severity failure;

        -- Reset after a result must blank the board outputs again.
        reset_top;

        wait;

    end process;

end architecture;
