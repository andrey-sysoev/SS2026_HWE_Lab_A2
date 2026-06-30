-- This block implements the classifier block.
--
-- It contains following blocks:
--   1. Input Interface  : stores SW(3 downto 0) into internal signal x
--   2. ROM Weights      : fixed constants W0, W1, W2, W3, and B
--   3. MAC / Dot Product: calculates z = W0*x0 + W1*x1 + W2*x2 + W3*x3 + B
--   4. Activation Unit  : outputs class_result = '1' when z >= 0, else '0'


entity classifier is
    port (
        -- Clock input from the FPGA board.
        -- The classifier updates only on the rising edge of this clock.
        clk          : in  bit;

        -- Reset input.
        -- When reset = '1', stored inputs, score, and class output are cleared immediately.
        reset        : in  bit;

        -- Four binary input features from FPGA switches.
        -- SW(0) is x0, SW(1) is x1, SW(2) is x2, SW(3) is x3.
        SW           : in  bit_vector(3 downto 0);

        -- Control signal from the control unit.
        -- When load_inputs = '1', the current switch values are stored into x.
        load_inputs  : in  bit;

        -- Control signal from the control unit.
        -- When compute_mac = '1', the weighted sum and class result are calculated.
        compute_mac  : in  bit;

        -- Output score of the classifier.
        -- Range is chosen large enough for the example weights below.
        -- These example weights will be replaced by 4-bit quantized real weight in demonstration.
        z            : out integer range -128 to 127;

        -- Final classification result.
        -- '1' means class 1, '0' means class 0.
        class_result : out bit
    );
end entity classifier;

architecture behavior of classifier is

    -- Internal input register.
    -- This stores the switch values after load_inputs is activated.
    -- Using a register means the classifier works with a stable copy of SW.
    signal x : bit_vector(3 downto 0);

    -- Internal score register.
    -- The output port z is connected to this signal at the end of the architecture.
    signal z_reg : integer range -128 to 127;

    -- Fixed weights and bias (ROM predefined variables).
    -- They are constants because the FPGA only do inference (no train).
    -- The example values will be replaced by real pre-trained model data.
    constant W0 : integer := 3;
    constant W1 : integer := -2;
    constant W2 : integer := 5;
    constant W3 : integer := -1;
    constant B  : integer := -4;

begin

    -- This process contains the input interface, MAC calculation,
    -- and activation unit.
    process(clk, reset)

        -- Local variable used only inside this process.
        -- Variables update immediately, so sum can be built step by step.
        variable sum : integer range -128 to 127;

    begin
        -- Asynchronous reset has priority over normal operation.
        if reset = '1' then

            -- Clear stored input features.
            x <= "0000";

            -- Clear stored score.
            z_reg <= 0;

            -- Clear class output.
            class_result <= '0';

        -- Rising edge clock detection using the built-in bit type.
        elsif clk'event and clk = '1' then

            -- Input Interface:
            -- Store the current switch values when the control unit requests it.
            if load_inputs = '1' then
                x <= SW;
            end if;

            -- MAC / Dot Product:
            -- Calculate weighted sum only when the control unit requests it.
            if compute_mac = '1' then

                -- Start with the bias value.
                sum := B;

                -- If x0 is active, add W0 (W0 * x0 = W0 * 1 = W0).
                -- If x0 is '0', add nothing (W0 * x0 = W0 * 0 = 0).
                if x(0) = '1' then
                    sum := sum + W0;
                end if;

                -- If x1 is active, add W1.
                -- If W1 is negative, it actually subtracts W1.
                if x(1) = '1' then
                    sum := sum + W1;
                end if;
                
                -- If x2 is active, add W2.
                -- If W2 is negative, it actually subtracts W2.
                if x(2) = '1' then
                    sum := sum + W2;
                end if;

                -- If x3 is active, add W3.
                -- If W3 is negative, it actually subtracts W3.
                if x(3) = '1' then
                    sum := sum + W3;
                end if;

                -- Store the final score into the score register.
                z_reg <= sum;

                -- Activation Unit:
                -- Convert the numeric score into class 0 or class 1.
                if sum >= 0 then
                    class_result <= '1';
                else
                    class_result <= '0';
                end if;

            end if;

        end if;
    end process;

    -- Connect the internal score register to the output port.
    z <= z_reg;

end architecture behavior;
