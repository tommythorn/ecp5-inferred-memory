/*
 * 20200321 Tommy Thorn
 */

module top
  (
   input wire clk48,
   input wire [20:0]  td,
   output reg tx = 0
  );

   reg         we = 0;
   reg [2:0]   funct3 = 0;
   reg [31:0]  addr = 0;
   reg [31:0]  writedata = 0;
   reg [31:0]  other_data = 0;
   wire [31:0] result;
   reg [7:0]   parity8 = 0;
   reg [1:0]   parity2 = 0;

   always @(posedge clk48)
     {we,funct3,addr,writedata,other_data}
       <= ~{other_data,funct3,writedata,addr,we} ^ td[19:0];

   `dut dut(clk48, we, funct3, addr, writedata, other_data, result);

   always @(posedge clk48) parity8 <= {
                                       ^result[31:28],
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
   input  wire        we,
   input  wire [ 2:0] funct3,
   input  wire [31:0] addr,
   input  wire [31:0] writedata,
   input  wire [31:0] other_data,

   output wire [31:0] result
   );


   reg [31:0]         memory[0:8191];

`ifdef write_first
   // 131 MHz when using sysMEM (DP16KD) memories
   // 297- MHz when using tiny LUTRAMs
   reg [31:0]         addr_r;
   always @(posedge clock) begin
      if (we)
        memory[addr] <= writedata;
      addr_r <= addr;
   end
   assign result = memory[addr_r];
`else // read_first
   // 131 MHz when using sysMEM (DP16KD) memories
   // 483- MHz when using tiny LUTRAMs
   reg [31:0]         readdata;
   always @(posedge clock) begin
      if (we)
        memory[addr] <= writedata;
      readdata <= memory[readdata];
   end
   assign result = readdata;
`endif
endmodule
