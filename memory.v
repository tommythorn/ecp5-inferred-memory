/*
 * 20200626 Tommy Thorn
 */

(* top *)
module top
  (
   input wire clk48,
   input wire [20:0]  td,
   output reg tx = 0
  );

   reg         write_enable = 0;
   reg [31:0]  write_address = 0;
   reg [31:0]  write_data = 0;
   reg [31:0]  read_address = 0;
   wire [31:0] read_data;
   reg [7:0]   parity8 = 0;
   reg [1:0]   parity2 = 0;

   reg [20:0]  td_r;

   always @(posedge clk48) td_r <= td;

   always @(posedge clk48)
     {write_enable, write_address, write_data, read_address}
       <=
    ~{read_address, write_data, write_address, write_enable} ^ td_r[19:0];

   genvar      x;
   generate
      for (x = 0; x < 32; x = x + 1) begin
         dpmem_16384x1 dut(clk48, write_enable, write_address, write_data[x], read_address, read_data[x]);
      end
   endgenerate

   always @(posedge clk48) parity8 <= {^read_data[31:28],
                                       ^read_data[27:24],
                                       ^read_data[23:20],
                                       ^read_data[19:16],
                                       ^read_data[15:12],
                                       ^read_data[11: 8],
                                       ^read_data[ 7: 4],
                                       ^read_data[ 3: 0]};
   always @(posedge clk48) parity2 <= {^parity8[7:4], ^parity8[3:0]};
   always @(posedge clk48) tx      <= ^parity2;
endmodule

/* BIG CAVEAT: reading and write the some same location simultaneously
   is not supported and may lead to incorrect results.  (This has not been
   verified.  In fact nothing has been verified about this other than timing). */

module dpmem_16384x1
  (input  wire        clock

  ,input  wire        write_enable
  ,input  wire [13:0] write_address
  ,input  wire        write_data
  ,input  wire [13:0] read_address

  ,output wire        read_data);

//`define manual 1
`ifdef manual
   // 233 MHz
   DP16KD
     #(.DATA_WIDTH_A(1)                 // 1,2,4,9 (default)
      ,.DATA_WIDTH_B(1)                 // 1,2,4,9 (default)
      ,.REGMODE_A("OUTREG")             // "NOREG" (default)  "OUTREG"
      ,.REGMODE_B("NOREG")             // "NOREG" (default)  "OUTREG"
      ,.WRITEMODE_A("NORMAL")           // "NORMAL" (default)  "WRITETHROUGH", "READBEFORE"
      ,.WRITEMODE_B("NORMAL")           // "NORMAL" (default)  "WRITETHROUGH", "READBEFORE"
      ,.GSR("ENABLED")                  // "ENABLED" (default)  "DISABLED"
      ,.RESETMODE("SYNC")               // "SYNC" (default)  "ASYNC"
      ,.ASYNC_RESET_RELEASE("SYNC")     // "SYNC" (default)  "ASYNC"
      )
   dpram
     (.ADA13(read_address[13])
     ,.ADA12(read_address[12])
     ,.ADA11(read_address[11])
     ,.ADA10(read_address[10])
     ,.ADA9(read_address[9])
     ,.ADA8(read_address[8])
     ,.ADA7(read_address[7])
     ,.ADA6(read_address[6])
     ,.ADA5(read_address[5])
     ,.ADA4(read_address[4])
     ,.ADA3(read_address[3])
     ,.ADA2(read_address[2])
     ,.ADA1(read_address[1])
     ,.ADA0(read_address[0])

     ,.CLKA(clock)
     ,.CEA(1)

     ,.ADB13(write_address[13])
     ,.ADB12(write_address[12])
     ,.ADB11(write_address[11])
     ,.ADB10(write_address[10])
     ,.ADB9(write_address[9])
     ,.ADB8(write_address[8])
     ,.ADB7(write_address[7])
     ,.ADB6(write_address[6])
     ,.ADB5(write_address[5])
     ,.ADB4(write_address[4])
     ,.ADB3(write_address[3])
     ,.ADB2(write_address[2])
     ,.ADB1(write_address[1])
     ,.ADB0(write_address[0])

     ,.DIB0(write_data)

     ,.CLKB(clock)
     ,.CEB(1)
     ,.RSTB(0)
     ,.WEB(write_enable)
     ,.CSB2(0)
     ,.CSB1(0)
     ,.CSB0(0)

      // Outputs
     ,.DOA0(read_data)
     );
`else
   reg array[16383:0];

//`define write_first
`ifdef write_first
   // 119 MHz
   reg [13:0] read_address1;
   reg        read_data2;

   wire read_data1 = array[read_address1];

   always @(posedge clock) begin
      if (write_enable)
        array[write_address] <= write_data;
      read_address1 <= read_address;
      read_data2 <= read_data1;
   end

   assign read_data = read_data2;
`else // read_first
   // 227 MHz
   reg                read_data1, read_data2;
   always @(posedge clock) begin
      if (write_enable)
        array[write_address] <= write_data;
      read_data1 <= array[read_address];
      read_data2 <= read_data1;
   end
   assign read_data = read_data2;
`endif
`endif
endmodule
