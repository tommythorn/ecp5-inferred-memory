/*
 * 20200321 Tommy Thorn
 */

`define MSB 31

module top
  (
   input wire clk48,
   input wire [20:0]  td,
   output reg tx = 0
  );

   reg         non_load = 0;
   reg [2:0]   funct3 = 0;
   reg [`MSB:0]  addr = 0;
   reg [`MSB:0]  memory_data = 0;
   reg [`MSB:0]  other_data = 0;
   wire [`MSB:0] result;
   reg [7:0]   parity8 = 0;
   reg [1:0]   parity2 = 0;

   always @(posedge clk48)
     {non_load,funct3,addr,memory_data,other_data}
       <= ~{other_data,funct3,memory_data,addr,non_load} ^ td[19:0];

   `dut dut(clk48, non_load, funct3, addr, memory_data, other_data, result);

   always @(posedge clk48) parity8 <= {
                                       ^result[`MSB:28],
                                       ^result[27:24],
                                       ^result[23:20],
                                       ^result[19:16],
                                       ^result[15:12],
                                       ^result[11: 8],
                                       ^result[ 7: 4],
                                       ^result[ 3: 0]};
   always @(posedge clk48) parity2 <= {^parity8[7:4], ^parity8[3:0]};
   always @(posedge clk48) tx      <= ^parity2;
endmodule

module memory
  (
   input  wire        clock,
   input  wire        non_load,
   input  wire [ 2:0] funct3,
   input  wire [`MSB:0] addr,
   input  wire [`MSB:0] memory_data,
   input  wire [`MSB:0] other_data,

   output wire [`MSB:0] result
   );


   reg [`MSB:0]         memory[0:1023]; // 4 KiB
   reg [`MSB:0]         addr_r = 0; // 4 KiB

   always @(posedge clock) begin
      if (non_load)
        memory[addr] <= memory_data;
      addr_r <= addr;
   end

   assign result = memory[addr_r];
endmodule
