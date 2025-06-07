module APB_TOP(
    input PCLK, PRESETn,
    input ST, WEN,
    input [8:0] APB_WADRS, APB_RADRS,
    input [7:0] APB_WDATA,
    output [7:0] APB_RDATA_OUT,
    output PSLVERR
);

    wire PSEL, PENABLE, PWRITE, PREADY;
    wire [8:0] PADDR;
    wire [7:0] PWDATA, PRDATA;

    // Instantiate Master
    APB_MASTER MASTER_INST (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PREADY(PREADY),
        .ST(ST),
        .WEN(WEN),
        .APB_WADRS(APB_WADRS),
        .APB_RADRS(APB_RADRS),
        .APB_WDATA(APB_WDATA),
        .PRDATA(PRDATA),
        .PSEL(PSEL),
        .PLSVERR(PSLVERR),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR),
        .PWDATA(PWDATA),
        .APB_RDATA_OUT(APB_RDATA_OUT)
    );

    // Instantiate Slave
    APB_SLAVE SLAVE_INST (
        .PCLK(PCLK),
        .PRESETn(PRESETn),
        .PSEL(PSEL),
        .PENABLE(PENABLE),
        .PWRITE(PWRITE),
        .PADDR(PADDR[7:0]), // using only 8 bits for addressing memory
        .PWDATA(PWDATA),
        .PRDATA(PRDATA),
        .PREADY(PREADY)
    );

endmodule
