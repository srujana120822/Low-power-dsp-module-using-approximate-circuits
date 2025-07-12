module mac_with_adders_16bit #(

    parameter DATA_WIDTH = 16

)(

    input  wire                     clk,   // system clock

    input  wire                     rst,   // synchronous reset (active high)

    input  wire                     start, // begins multiply-accumulate

    input  wire [DATA_WIDTH-1:0]    a,     // multiplier input

    input  wire [DATA_WIDTH-1:0]    b,     // multiplicand input

    output reg                      done,  // high when operation finished

    output reg [2*DATA_WIDTH-1:0]   acc    // accumulated product result

);


    // Local copies of inputs for shift-add iteration

    reg [DATA_WIDTH-1:0] multiplier, multiplicand;

    reg [2*DATA_WIDTH-1:0] product; // holds running partial product

    reg [5:0] count;               // tracks iteration; 6 bits covers up to 16 cycles

    reg [1:0] current_state, next_state;


    // FSM state definitions (Moore FSM style) :contentReference[oaicite:1]{index=1}

    localparam IDLE     = 2'b00,

               LOAD     = 2'b01,

               MULTIPLY = 2'b10,

               DONE     = 2'b11;


    // Present-state register: synchronous state transitions with reset :contentReference[oaicite:2]{index=2}

    always @(posedge clk or posedge rst) begin

        if (rst)

            current_state <= IDLE;

        else

            current_state <= next_state;

    end


    // Next-state combinational logic :contentReference[oaicite:3]{index=3}

    always @(*) begin

        case (current_state)

            IDLE:     next_state = start ? LOAD : IDLE;

            LOAD:     next_state = MULTIPLY;

            MULTIPLY: next_state = (count == DATA_WIDTH) ? DONE : MULTIPLY;

            DONE:     next_state = IDLE;

            default:  next_state = IDLE;

        endcase

    end


    // Data path and control outputs based on state

    always @(posedge clk or posedge rst) begin

        if (rst) begin

            // Reset all registers and flags

            multiplier   <= 0;

            multiplicand <= 0;

            product      <= 0;

            acc          <= 0;

            count        <= 0;

            done         <= 0;

        end else begin

            case (current_state)

                IDLE: begin

                    done <= 0;  // ensure done flag cleared before new operation

                end


                LOAD: begin

                    // Capture inputs and initialize for shift-add multiplication

                    multiplier   <= a;

                    multiplicand <= b;

                    product      <= 0;

                    count        <= 0;

                end


                MULTIPLY: begin

                    // Core shift-add logic :contentReference[oaicite:4]{index=4}

                    // If LSB is 1, add (multiplicand << count) to product

                    if (multiplier[0])

                        product <= product + (multiplicand << count);


                    // Shift multiplier right to process next bit

                    multiplier <= multiplier >> 1;

                    count <= count + 1;

                end


                DONE: begin

                    // Add final product into accumulator and assert done flag

                    acc  <= acc + product;

                    done <= 1;

                end

            endcase

        end

    end


endmodule


