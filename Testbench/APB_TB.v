`timescale 1ns/1ps

module APB_TB();

  reg PCLK;
  reg PRESETn;
  reg ST;
  reg WEN;
  reg [8:0] APB_WADRS;
  reg [8:0] APB_RADRS;
  reg [7:0] APB_WDATA;
  wire [7:0] APB_RDATA_OUT;
  wire PSLVERR;

  // Instantiate the TOP module
  APB_TOP uut (
    .PCLK(PCLK),
    .PRESETn(PRESETn),
    .ST(ST),
    .WEN(WEN),
    .APB_WADRS(APB_WADRS),
    .APB_RADRS(APB_RADRS),
    .APB_WDATA(APB_WDATA),
    .APB_RDATA_OUT(APB_RDATA_OUT),
    .PSLVERR(PSLVERR)
  );

  // Clock Generation
  always #5 PCLK = ~PCLK;

  // Task for APB-compliant 2-cycle write
  task write_data(input [8:0] addr, input [7:0] data);
  begin
    APB_WADRS = addr;
    APB_WDATA = data;
    WEN = 1;

    // Setup phase
    ST = 1;
    #10;

    // Access phase
    ST = 0;
    #10;

    // Optional: wait 1 cycle for visibility
    #10;
  end
  endtask

  // Task for APB-compliant 2-cycle read and checking result
  task read_and_check(input [8:0] addr, input [7:0] expected);
  begin
    APB_RADRS = addr;
    WEN = 0;

    // Setup phase
    ST = 1;
    #10;

    // Access phase
    ST = 0;
    #10;

    // Wait to capture output
    #10;

    if (APB_RDATA_OUT === expected)
      $display("[PASS] Read from 0x%0h = 0x%0h", addr, APB_RDATA_OUT);
    else
      $display("[FAIL] Read from 0x%0h = 0x%0h, Expected = 0x%0h", addr, APB_RDATA_OUT, expected);
  end
  endtask

  initial begin
    $display("Starting Simulation");
    PCLK = 0;
    PRESETn = 0;
    ST = 0;
    WEN = 0;
    APB_WADRS = 0;
    APB_RADRS = 0;
    APB_WDATA = 0;

    // Reset sequence
    #10; PRESETn = 1;

    // Test Case 1: Write and Read 0xAA at address 0x05
    write_data(9'h05, 8'hAA);
    read_and_check(9'h05, 8'hAA);

    // Test Case 2: Write and Read 0x55 at address 0x10
    write_data(9'h10, 8'h55);
    read_and_check(9'h10, 8'h55);

    // Test Case 3: Write and Read 0x00 at address 0x00
    write_data(9'h00, 8'h00);
    read_and_check(9'h00, 8'h00);

    // Test Case 4: Write and Read 0xFF at address 0x3F
    write_data(9'h3F, 8'hFF);
    read_and_check(9'h3F, 8'hFF);

    // Optional: Test Case 5 - invalid address (out of memory range)
    write_data(9'h40, 8'hDE);         // Should trigger PSLVERR or be ignored
    read_and_check(9'h40, 8'hxx);     // Undefined behavior, used for testing

    // Finish Simulation
    #20;
    $display("Simulation Finished");
    $stop;
  end

endmodule
