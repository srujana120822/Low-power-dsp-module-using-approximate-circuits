// Approximate Lower-part OR Adder (LoA)

module loa_adder16 #(parameter LOWER_WIDTH = 3)(

  input  [15:0] a,

  input  [15:0] b,

  output [15:0] sum

);

  wire [LOWER_WIDTH-1:0] lower_sum;

  wire [15:LOWER_WIDTH] upper_sum;


  // Use OR for lower bits (approximate)

  assign lower_sum = a[LOWER_WIDTH-1:0] | b[LOWER_WIDTH-1:0];

  // Accurate addition for upper bits

  assign upper_sum = a[15:LOWER_WIDTH] + b[15:LOWER_WIDTH];


  // Form final 16-bit sum

  assign sum = {upper_sum, lower_sum};

endmodule


// Multiply-Accumulate (MAC) unit using LoA in partial accumulator updates

module mac_16bit_loa (

  input  wire        clk,

  input  wire        rst,

  input  wire        start,

  input  wire [15:0] a,

  input  wire [15:0] b,

  output reg         done,

  output reg  [31:0] acc

);

  reg [4:0]  bit_index;

  reg        processing;

  reg [31:0] partial_product;

  wire [15:0] loa_sum;


  // LoA instance — approximates lower 3 bits of acc update

  loa_adder16 #(.LOWER_WIDTH(3)) loa_inst (

    .a(acc[15:0]),

    .b(partial_product[15:0]),

    .sum(loa_sum)

  );


  always @(posedge clk or posedge rst) begin

    if (rst) begin

      acc         <= 0;

      bit_index   <= 0;

      processing  <= 0;

      done        <= 0;

    end else begin

      if (start && !processing) begin

        // Begin new MAC operation

        acc        <= 0;

        bit_index  <= 0;

        done       <= 0;

        processing <= 1;

      end else if (processing) begin

        if (bit_index < 16) begin

          if (a[bit_index]) begin

            // Generate partial product by shifting

            partial_product = b << bit_index;

            // Approximate-add lower 16 bits, exact-add upper 16 bits

            acc[15:0]   <= loa_sum;

            acc[31:16]  <= acc[31:16] + partial_product[31:16];

          end

          bit_index <= bit_index + 1;

        end else begin

          // MAC complete

          processing <= 0;

          done       <= 1;

        end

      end

    end

  end

endmodule
