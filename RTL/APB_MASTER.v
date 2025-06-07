module APB_MASTER(PCLK,PRESETn,PREADY,ST,WEN,APB_WADRS,APB_RADRS,APB_WDATA,PRDATA,PSEL,PLSVERR,PENABLE,PWRITE,PADDR,PWDATA,APB_RDATA_OUT);
input ST,WEN;
input [8:0] APB_WADRS,APB_RADRS;
input [7:0] APB_WDATA;
output [7:0] APB_RDATA_OUT;

input PCLK,PRESETn,PREADY;
input [7:0] PRDATA;
output reg PSEL,PLSVERR;
output reg PENABLE,PWRITE;
output reg [8:0] PADDR;
output reg [7:0] PWDATA;

// State Variables
reg [1:0] PS,NS;
localparam  IDLE=2'b00,
            SETUP=2'b01,
            ACCESS=2'b10;

// PSLVERR Error Detection Signals
reg setup_error;
reg invalid_read_paddr;
reg invalid_write_paddr;
reg invalid_write_data;
reg invalid_setup_error;

// Data Registers
reg [7:0] rdata;
assign APB_RDATA_OUT = rdata;

// Read/Write direction detection
wire READ_WRITE = WEN ? 0 : 1;
wire [8:0] apb_write_paddr = APB_WADRS;
wire [8:0] apb_read_paddr  = APB_RADRS;
wire [7:0] apb_write_data  = APB_WDATA;

// State Register Logic
always @(posedge PCLK)
begin
    if(!PRESETn)
        PS<=IDLE;
    else
        PS<=NS;
end

// Next State logic
always @(PS,ST,PREADY)
begin
    case(PS)
        IDLE:
        begin
            if(ST)
            begin
                NS<=SETUP;
            end
            else
            begin
                NS<=IDLE;
            end
        end
        SETUP:
        begin
            NS<=ACCESS;
        end
        ACCESS:
        begin
            if(!PREADY)
                NS<=ACCESS;
            else
            begin
                if(ST)
                    NS<=SETUP;
                else
                    NS<=IDLE;
            end
        end
        default:NS<=IDLE;
    endcase
end

// OUTPUT Logic
always @(PS,ST,PREADY)
begin
    case(PS)
        IDLE:
        begin
            PSEL     <= 0;
            PENABLE  <= 0;
            PWRITE   <= 0;
            PADDR    <= 0;
            PWDATA   <= 0;
            PLSVERR  <= 0;
        end
        SETUP:
        begin
            PSEL    <= 1;
            PENABLE <= 0;
            PWRITE  <= WEN;
            PADDR   <= WEN ? APB_WADRS : APB_RADRS;
            PWDATA  <= APB_WDATA;
        end
        ACCESS:
        begin
            PSEL    <= 1;
            PENABLE <= 1;
            if (!WEN && PREADY)
                rdata <= PRDATA;
        end
        default:
        begin
            PSEL     <= 0;
            PENABLE  <= 0;
            PWRITE   <= 0;
            PADDR    <= 0;
            PWDATA   <= 0;
            PLSVERR  <= 0;
        end
    endcase
end

// PSLVERR LOGIC
always @(*)
begin
    if (!PRESETn)
    begin 
        setup_error         = 0;
        invalid_read_paddr  = 0;
        invalid_write_paddr = 0;
        invalid_write_data  = 0;
    end
    else
    begin	
        // remove this: if (PS == IDLE && NS == ACCESS)

        invalid_write_data  = (!READ_WRITE && (apb_write_data === 8'dx));
        invalid_read_paddr  = (READ_WRITE && (apb_read_paddr === 9'dx));
        invalid_write_paddr = (!READ_WRITE && (apb_write_paddr === 9'dx));

        // You can optionally check for address range violations
        if (PADDR > 9'h03F)
            setup_error = 1'b1;
        else
            setup_error = 1'b0;
    end

    invalid_setup_error = setup_error || invalid_read_paddr || invalid_write_data || invalid_write_paddr;
end

// Assign final error signal
always @(posedge PCLK)
begin
    if(!PRESETn)
        PLSVERR <= 0;
    else
        PLSVERR <= invalid_setup_error;
end

endmodule
