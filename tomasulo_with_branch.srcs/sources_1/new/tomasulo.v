`timescale 1ns / 1ps
//////////////////////////////////////////////////////////////////////////////////
// Company: 
// Engineer: 
// 
// Create Date: 16.07.2026 11:37:57
// Design Name: 
// Module Name: tomasulo
// Project Name: 
// Target Devices: 
// Tool Versions: 
// Description: 
// 
// Dependencies: 
// 
// Revision:
// Revision 0.01 - File Created
// Additional Comments:
// 
//////////////////////////////////////////////////////////////////////////////////

`define no_ARF 10
`define no_RAT 10
`define no_instr 8
`define no_RS_addsub 3
`define no_RS_muldiv 2
`define no_LoadStoreBuffer 3
`define no_RS_branch 2
`define no_ROB 9
`define main_memory_length 100

//RISC-V RV-32I set, {func7,func3,opcode}
`define beq 10'b000_1100011
`define lw  10'b010_0000011 
`define add 17'b0000000_000_0110011 
`define sub 17'b0100000_000_0110011 
`define mul 17'b0000001_000_0110011 
`define div 17'b0000001_100_0110011 

module tomasulo(
input clk, input rst, output reg done
    );
reg stall;
reg[31:0]pc;
reg[31:0]instruction_memory[`no_instr-1:0];
reg[$clog2(`no_instr)-1:0]instr_ID;

reg RS_AddSub_busy;
reg RS_MulDiv_busy;
reg LS_Busy;
reg RS_Branch_busy;
reg[$clog2(`no_ROB)-1:0]ROB_issue;
reg[$clog2(`no_ROB)-1:0]ROB_commit;

reg[31:0]ARF[1:`no_ARF];

reg[$clog2(`no_ROB)-1:0]RAT[1:`no_RAT];

reg [7:0] main_memory[`main_memory_length*4:0];

//ROB table
reg [$clog2(`no_instr)-1:0]ROB_instr_ID[`no_ROB:1];
reg [$clog2(`no_ARF)-1:0]ROB_dest[`no_ROB:1];
reg [31:0]ROB_value[`no_ROB:1];
reg ROB_valid[`no_ROB:1];


//ADD_SUB RS Table
reg [$clog2(`no_instr)-1:0]AS_RS_instr_ID[`no_RS_addsub-1:0];
reg [16:0]AS_RS_instr[`no_RS_addsub-1:0];
reg AS_RS_busy[`no_RS_addsub-1:0];
reg [$clog2(`no_ARF)-1:0]AS_RS_dest[`no_RS_addsub-1:0];
reg [$clog2(`no_ARF)-1:0]AS_RS_src1[`no_RS_addsub-1:0];
reg [$clog2(`no_ARF)-1:0]AS_RS_src2[`no_RS_addsub-1:0];
reg [31:0]AS_RS_value1[`no_RS_addsub-1:0];
reg [31:0]AS_RS_value2[`no_RS_addsub-1:0];

//MUL_DIV Table
reg [$clog2(`no_instr)-1:0]MD_RS_instr_ID[`no_RS_muldiv-1:0];
reg [16:0]MD_RS_instr[`no_RS_muldiv-1:0];
reg MD_RS_busy[`no_RS_muldiv-1:0];
reg [$clog2(`no_ARF)-1:0]MD_RS_dest[`no_RS_muldiv-1:0];
reg [$clog2(`no_ARF)-1:0]MD_RS_src1[`no_RS_muldiv-1:0];
reg [$clog2(`no_ARF)-1:0]MD_RS_src2[`no_RS_muldiv-1:0];
reg [31:0]MD_RS_value1[`no_RS_muldiv-1:0];
reg [31:0]MD_RS_value2[`no_RS_muldiv-1:0];

//Load Store Buffer
reg [$clog2(`no_instr)-1:0]LS_buffer_instr_ID[`no_LoadStoreBuffer-1:0];
reg LS_buffer_busy[`no_LoadStoreBuffer-1:0];
reg [$clog2(`no_ARF)-1:0]LS_buffer_dest_tag[`no_LoadStoreBuffer-1:0];
reg [11:0] LS_buffer_offset[`no_LoadStoreBuffer-1:0];
reg [$clog2(`no_ARF)-1:0]LS_buffer_SRCreg[`no_LoadStoreBuffer-1:0];
reg [31:0]src_reg_value[`no_LoadStoreBuffer-1:0];

//Branch table
reg [$clog2(`no_instr)-1:0]Branch_instr_ID[`no_RS_branch-1:0];
reg Branch_RS_busy[`no_RS_branch-1:0];
reg [$clog2(`no_ARF)-1:0]Branch_RS_src1[`no_RS_branch-1:0];
reg [$clog2(`no_ARF)-1:0]Branch_RS_src2[`no_RS_branch-1:0];
reg [31:0]Branch_RS_value1[`no_RS_branch-1:0];
reg [31:0]Branch_RS_value2[`no_RS_branch-1:0];


reg [31:0] instr_IQ;


always@(posedge clk)
begin
if(rst==1)
begin
pc<=0;
instr_IQ<=0;
done<=0;
stall<=0;
ARF[1]<=12;
ARF[2]<=16;
ARF[3]<=45;
ARF[4]<=5;
ARF[5]<=3;
ARF[6]<=4;
ARF[7]<=1;
ARF[8]<=2;
ARF[9]<=2;
ARF[10]<=16;

RAT[1]<=0;
RAT[2]<=0;
RAT[3]<=0;
RAT[4]<=0;
RAT[5]<=0;
RAT[6]<=0;
RAT[7]<=0;
RAT[8]<=0;
RAT[9]<=0;
RAT[10]<=0;

main_memory[16]<=16;

instruction_memory[0] <= 32'b0000_0000_0000_0001_0010_0001_1000_0011;
instruction_memory[1] <= 32'b0000_0000_1010_0001_1000_0011_0110_0011;//
instruction_memory[2] <= 32'b0000_0010_0100_0001_1100_0001_0011_0011;
instruction_memory[3] <= 32'b0000_0010_0110_0010_1000_0000_1011_0011;
instruction_memory[4] <= 32'b0000_0000_1000_0011_1000_0001_1011_0011;
instruction_memory[5] <= 32'b0000_0010_0011_0000_1000_0000_1011_0011;
instruction_memory[6] <= 32'b0100_0000_0101_0000_1000_0010_0011_0011;
instruction_memory[7] <= 32'b0000_0000_0010_0010_0000_0000_1011_0011;
end

else if(stall==1)
begin
pc<=pc;
instr_IQ<=instr_IQ;
end

else if(pc>`no_instr)
begin
pc<=pc;
instr_IQ<=instr_IQ;
end

else
begin
instr_IQ<=instruction_memory[pc];
pc<=pc+1;
end
end

wire[6:0]func7;
wire[2:0]func3;
wire[6:0]opcode;
wire[4:0]src1;
wire[4:0]src2;
wire[4:0]dst;
wire[11:0]offset;

assign func7=instr_IQ[31:25];
assign offset=instr_IQ[31:20];
assign src2=instr_IQ[24:20];
assign src1=instr_IQ[19:15];
assign func3=instr_IQ[14:12];
assign dst=instr_IQ[11:7];
assign opcode=instr_IQ[6:0];


integer r,updated;

always @(posedge clk)
begin

    if(rst == 1)
    begin
        instr_ID <= 1;
    end

    else if(stall == 1)
    begin
        instr_ID <= instr_ID;
        ROB_issue <= ROB_issue;
    end

    else
    begin

        case({func7,func3,opcode})

            {offset[11:5],`lw}:
            begin

                if(LS_Busy == 1'b1)
                    stall <= 1;

                else
                begin

                    updated = 0;

                    for(r=0; r<`no_LoadStoreBuffer; r=r+1)
                    begin : loop_ls

                        if(updated==0 && LS_buffer_busy[r]==0)
                        begin
                            if(RAT[src1]!=0)LS_buffer_SRCreg[r]=RAT[src1];else src_reg_value[r]<=ARF[src1];
                            LS_buffer_instr_ID[r] <= instr_ID;
                            LS_buffer_busy[r]     <= 1'b1;
                            LS_buffer_dest_tag[r] <= ROB_issue;
                            LS_buffer_offset[r]   <= offset;
                            updated = 1;
                        end

                    end

                

                ROB_instr_ID[ROB_issue] <= instr_ID;
                ROB_dest[ROB_issue]     <= dst;
                ROB_value [ROB_issue] <= 32'hxxxxxxxx;

                RAT[dst] <= ROB_issue;

                ROB_issue <= ROB_issue + 1;
                instr_ID  <= instr_ID + 1;
            end
            end
          `add:begin
                    if(RS_AddSub_busy==1'b1)stall<=1;
                    else
                    begin
                        updated=0;
                        for(r=0;r<`no_RS_addsub;r=r+1)
                        begin
                            if(updated==0&&AS_RS_busy[r]==0)
                                begin
                                AS_RS_busy[r]<=1'b1;
                                AS_RS_instr[r]<=`add;
                                AS_RS_instr_ID[r]<=instr_ID;
                                AS_RS_dest[r]<=ROB_issue;
                                if(RAT[src1]!=0)AS_RS_src1[r]=RAT[src1];else AS_RS_value1[r]<=ARF[src1];
                                if(RAT[src2]!=0)AS_RS_src2[r]=RAT[src2];else AS_RS_value2[r]<=ARF[src2];
                                updated=1;
                                end
                        end
                        ROB_instr_ID[ROB_issue]<=instr_ID;
                        ROB_dest[ROB_issue]<=dst;
                        ROB_value [ROB_issue] <= 32'hxxxxxxxx;
                        
                        RAT[dst]<=ROB_issue;
                        
                        ROB_issue<=ROB_issue+1;
                        instr_ID<=instr_ID+1;
                    end     
                end  
           `sub:begin
                    if(RS_AddSub_busy==1'b1)stall<=1;
                    else
                    begin
                        updated=0;
                        for(r=0;r<`no_RS_addsub;r=r+1)
                        begin
                            if(updated==0&&AS_RS_busy[r]==0)
                                begin
                                AS_RS_busy[r]<=1'b1;
                                AS_RS_instr[r]<=`sub;
                                AS_RS_instr_ID[r]<=instr_ID;
                                AS_RS_dest[r]<=ROB_issue;
                                if(RAT[src1]!=0)AS_RS_src1[r]<=RAT[src1];else AS_RS_value1[r]<=ARF[src1];
                                if(RAT[src2]!=0)AS_RS_src2[r]<=RAT[src2];else AS_RS_value2[r]<=ARF[src2];
                                updated=1;
                                end
                        end
                        ROB_instr_ID[ROB_issue]<=instr_ID;
                        ROB_dest[ROB_issue]<=dst;
                        ROB_value [ROB_issue] <= 32'hxxxxxxxx;
                        
                        RAT[dst]<=ROB_issue;
                        
                        ROB_issue<=ROB_issue+1;
                        instr_ID<=instr_ID+1;
                    end     
                end 
                `mul:begin
                    if(RS_MulDiv_busy==1'b1)stall<=1;
                    else
                    begin
                        updated=0;
                        for(r=0;r<`no_RS_muldiv;r=r+1)
                        begin
                            if(updated==0&&MD_RS_busy[r]==0)
                                begin
                                MD_RS_busy[r]<=1'b1;
                                MD_RS_instr[r]<=`mul;
                                MD_RS_instr_ID[r]<=instr_ID;
                                MD_RS_dest[r]<=ROB_issue;
                                if(RAT[src1]!=0)MD_RS_src1[r]=RAT[src1];else MD_RS_value1[r]<=ARF[src1];
                                if(RAT[src2]!=0)MD_RS_src2[r]=RAT[src2];else MD_RS_value2[r]<=ARF[src2];
                                updated=1;
                                end
                        end
                        ROB_instr_ID[ROB_issue]<=instr_ID;
                        ROB_dest[ROB_issue]<=dst;
                        ROB_value [ROB_issue] <= 32'hxxxxxxxx;
                        
                        RAT[dst]<=ROB_issue;
                        
                        ROB_issue<=ROB_issue+1;
                        instr_ID<=instr_ID+1;
                    end     
                end  
                `div:begin
                    if(RS_MulDiv_busy==1'b1)stall<=1;
                    else
                    begin
                        updated=0;
                        for(r=0;r<`no_RS_muldiv;r=r+1)
                        begin
                            if(updated==0&&MD_RS_busy[r]==0)
                                begin
                                MD_RS_busy[r]<=1'b1;
                                MD_RS_instr[r]<=`div;
                                MD_RS_instr_ID[r]<=instr_ID;
                                MD_RS_dest[r]<=ROB_issue;
                                if(RAT[src1]!=0)MD_RS_src1[r]=RAT[src1];else MD_RS_value1[r]<=ARF[src1];
                                if(RAT[src2]!=0)MD_RS_src2[r]=RAT[src2];else MD_RS_value2[r]<=ARF[src2];
                                updated=1;
                                end
                        end
                        ROB_instr_ID[ROB_issue]<=instr_ID;
                        ROB_dest[ROB_issue]<=dst;
                        ROB_value [ROB_issue] <= 32'hxxxxxxxx;
                        
                        RAT[dst]<=ROB_issue;
                        
                        ROB_issue<=ROB_issue+1;
                        instr_ID<=instr_ID+1;
                    end     
                end 
                
            {offset[11:5],`beq}:
            begin
            if(RS_Branch_busy==1'b1)stall<=1;
            else
            begin
            updated=0;
            for(r=0;r<`no_RS_branch;r=r+1)
                        begin
                            if(updated==0&&Branch_RS_busy[r]==0)
                                begin
                                Branch_RS_busy[r]<=1'b1;
                                Branch_instr_ID[r]<=instr_ID;
                                if(RAT[src1]!=0)Branch_RS_src1[r]=RAT[src1];else Branch_RS_value1[r]<=ARF[src1];
                                if(RAT[src2]!=0)Branch_RS_src2[r]=RAT[src2];else Branch_RS_value2[r]<=ARF[src2];
                                updated=1;
                        end
                        ROB_instr_ID[ROB_issue]<=instr_ID;
                        ROB_dest[ROB_issue]<=4'b1111;
                        ROB_value [ROB_issue] <= 32'hxxxxxxxx;
                        
                        //RAT[dst]<=ROB_issue;
                        
                        ROB_issue<=ROB_issue+1;
                        instr_ID<=instr_ID+1;
                        end
                        
                        
            end
            
            
            
            end
            default:begin
            end

        endcase

    end

end



reg [$clog2(`no_ARF)-1:0]CDB_dest;
reg [31:0] CDB_value;









integer j,t,y;
reg [31:0] Branch_src1,Branch_src2;
reg[$clog2(`no_instr)-1:0]B_instr_ID;
reg Branch_start;
reg Branch_counter_run;
reg Branch_updated;
reg Branch_valid;
always@(posedge clk)
begin
    if(Branch_start==1)Branch_start<=0;
    if((Branch_RS_busy[0]+Branch_RS_busy[1])==2)
    RS_Branch_busy<=1;
    else
    RS_Branch_busy<=0;
    
    if(rst==1)begin
    for(j=0;j<`no_RS_branch;j=j+1)
        begin
            Branch_instr_ID[j]<=0;
            Branch_RS_busy[j]<=0;
            Branch_RS_src1[j]<=0;
            Branch_RS_src2[j]<=0;
            Branch_RS_value1[j]<=0;
            Branch_RS_value2[j]<=0;
        end
    end
    else begin
    Branch_updated<=0;
    for(t=0;t<`no_RS_addsub;t=t+1)
        begin
            if(Branch_RS_src1[t]==CDB_dest&&CDB_dest!=0)
            begin
                Branch_RS_value1[t]<=CDB_value;
                Branch_RS_src1[t]<=0;
            end
            if(Branch_RS_src2[t]==CDB_dest&&CDB_dest!=0)
            begin
                Branch_RS_value2[t]<=CDB_value;
                Branch_RS_src2[t]<=0;
            end
        end
    for(j=0;j<`no_RS_addsub;j=j+1)
        begin
            if(Branch_counter_run==0&&Branch_updated==0&&Branch_RS_busy[j]==1&&Branch_RS_src1[j]==0&&Branch_RS_src2[j]==0)
            begin
                Branch_src1<=Branch_RS_value1[j];
                Branch_src2<=Branch_RS_value2[j];
                B_instr_ID <= Branch_instr_ID[j];
                Branch_RS_busy[j]<=1'b0;
                Branch_start<=1;
                Branch_updated<=1;
            end
        end

    end
    
end

reg [2:0]Branch_counter;
reg [31:0]Branch_result;
always@(posedge clk)
begin
if(rst==1)
    begin
        Branch_counter<=0;
        Branch_result<=0;
        Branch_valid<=0;
        Branch_counter_run<=0;
    end
else if(Branch_start==1)
begin
    Branch_result<=(Branch_src1==Branch_src2);
    Branch_counter<=0;
    Branch_valid<=0;
    Branch_counter_run<=1;
end
else if(Branch_counter_run==1)
begin
    Branch_valid<=1;
    Branch_counter<=0;
    Branch_counter_run<=0;
    
end
end






















































integer k,l;
reg [31:0]LS_value;
reg[$clog2(`no_ROB)-1:0]LS_dest;
reg[$clog2(`no_instr)-1:0]LS_instr_ID;
reg [11:0] LS_offset;
reg LS_start;
reg LS_counter_run;
reg LS_updated;
reg LS_valid;

always@(posedge clk)
begin
    if(LS_start==1)LS_start<=0;
    
    if((LS_buffer_busy[0]+LS_buffer_busy[1]+LS_buffer_busy[2])==3)LS_Busy<=1;
    else LS_Busy<=0;
    
    if(rst==1)
    begin
    for(k=0;k<`no_LoadStoreBuffer;k=k+1)
        begin
            LS_buffer_instr_ID[k]<=0;
            LS_buffer_busy[k]<=0;
            LS_buffer_dest_tag[k]<=0;
            LS_buffer_offset[k]<=0;
            LS_buffer_SRCreg[k]<=0;
            LS_updated<=0;
        end
    end
    else
    begin
        LS_updated<=0;
        for(t=0;t<`no_LoadStoreBuffer;t=t+1)
        begin
            if(LS_buffer_SRCreg[t]==CDB_dest&&CDB_dest!=0)
            begin
                src_reg_value[t]<=CDB_value;
                LS_buffer_SRCreg[t]<=0;
            end
         end
        for(l=0;l<`no_LoadStoreBuffer;l=l+1)
            begin
                if(LS_counter_run==0&&LS_updated==0&&LS_buffer_busy[l]!=0&&LS_buffer_SRCreg[l]==0)
                begin
                    LS_value<=src_reg_value[l];
                    LS_dest<=LS_buffer_dest_tag[l];
                    LS_instr_ID<=LS_buffer_instr_ID[l];
                    LS_offset<=LS_buffer_offset[l];
                    LS_buffer_busy[l]<=1'b0;
                    LS_start<=1;
                    LS_updated<=1;
                end
            end
    end
    
    
end



reg[31:0] LS_result;
reg[2:0]LS_counter;

always@(posedge clk)
begin
    if(rst==1)
    begin
        LS_counter<=0;
        LS_result<=0;
        LS_valid<=0;
        LS_counter_run<=0;
    end
    else if(LS_start==1)
    begin
        LS_counter<=0;
        LS_result<=main_memory[LS_offset+LS_value];
        LS_valid<=0;
        LS_counter_run<=1;
    end
    else if(LS_counter>3)
    begin
        LS_valid<=1;
        LS_counter<=0;
        LS_counter_run<=0;
    end
    else if(LS_counter_run==1)LS_counter<=LS_counter+1;
end


reg [31:0] AS_src1,AS_src2;
reg [$clog2(`no_ROB)-1:0]AS_dest;
reg[16:0]AS_instr;
reg[$clog2(`no_instr)-1:0]AS_instr_ID;
reg AS_start;
reg AS_counter_run;
reg AS_updated;
reg AS_valid;
always@(posedge clk)
begin
    if(AS_start==1)AS_start<=0;
    if((AS_RS_busy[0]+AS_RS_busy[1]+AS_RS_busy[2])==3)
    RS_AddSub_busy<=1;
    else
    RS_AddSub_busy<=0;
    
    if(rst==1)begin
    for(j=0;j<`no_RS_addsub;j=j+1)
        begin
            AS_RS_instr_ID[j]<=0;
            AS_RS_instr[j]<=0;
            AS_RS_busy[j]<=0;
            AS_RS_dest[j]<=0;
            AS_RS_src1[j]<=0;
            AS_RS_src2[j]<=0;
            AS_RS_value1[j]<=0;
            AS_RS_value2[j]<=0;
        end
    end
    else begin
    AS_updated<=0;
    for(t=0;t<`no_RS_addsub;t=t+1)
        begin
            if(AS_RS_src1[t]==CDB_dest&&CDB_dest!=0)
            begin
                AS_RS_value1[t]<=CDB_value;
                AS_RS_src1[t]<=0;
            end
            if(AS_RS_src2[t]==CDB_dest&&CDB_dest!=0)
            begin
                AS_RS_value2[t]<=CDB_value;
                AS_RS_src2[t]<=0;
            end
        end
    for(j=0;j<`no_RS_addsub;j=j+1)
        begin
            if(AS_counter_run==0&&AS_updated==0&&AS_RS_busy[j]==1&&AS_RS_src1[j]==0&&AS_RS_src2[j]==0)
            begin
                AS_src1<=AS_RS_value1[j];
                AS_src2<=AS_RS_value2[j];
                AS_dest<=AS_RS_dest[j];
                AS_instr<=AS_RS_instr[j];
                AS_instr_ID <= AS_RS_instr_ID[j];
                AS_RS_busy[j]<=1'b0;
                AS_start<=1;
                AS_updated<=1;
            end
        end

    end
    
end

reg [2:0]AS_counter;
reg [31:0]AS_result;
always@(posedge clk)
begin
if(rst==1)
    begin
        AS_counter<=0;
        AS_result<=0;
        AS_valid<=0;
        AS_counter_run<=0;
    end
else if(AS_start==1)
begin
    if(AS_instr==`add)
    AS_result<=AS_src1+AS_src2;
    else if(AS_instr==`sub)
    AS_result<=AS_src1-AS_src2;
    AS_counter<=0;
    AS_valid<=0;
    AS_counter_run<=1;
end
else if(AS_counter_run==1)
begin
    AS_valid<=1;
    AS_counter<=0;
    AS_counter_run<=0;
    
end
end

  reg [31:0]MD_src1,MD_src2;
    reg [$clog2(`no_ROB)-1:0]MD_dest;
    reg [16:0]MD_instr;
    reg [$clog2(`no_instr)-1:0]MD_instr_ID;
    reg MD_start;
    reg MD_counter_run;
    reg MD_updated;
    reg MD_valid;
    always@(posedge clk)
    begin
     if(MD_start == 1) MD_start <= 0;
     if((MD_RS_busy[0]+MD_RS_busy[1]) > 2)     RS_MulDiv_busy <= 1;
     else RS_MulDiv_busy <= 0;
     
     if(rst==1) begin
         MD_start <= 0; //MD_src1 <= 0; MD_src2 <= 0;
         for(j = 0; j < `no_RS_muldiv; j = j + 1) begin 
            MD_RS_instr_ID[j] <= 0; 
            MD_RS_instr[j] <= 0;  
            MD_RS_busy[j] <= 0;   
            MD_RS_dest[j] <= 0;   
            MD_RS_src1[j] <= 0;   
            MD_RS_src2[j] <= 0;   
            MD_RS_value1[j] <= 0;   
            MD_RS_value2[j] <= 0; 
            end 
     end
     
     else begin
         MD_updated <= 0;
         for(t = 0 ; t < `no_RS_muldiv; t = t +1 ) begin
            if(MD_RS_src1[t] == CDB_dest && CDB_dest != 0) begin MD_RS_value1[t] <= CDB_value; MD_RS_src1[t] <= 0; end
            if(MD_RS_src2[t] == CDB_dest && CDB_dest != 0) begin MD_RS_value2[t] <= CDB_value; MD_RS_src2[t] <= 0; end
            end
         for(j = 0; j < `no_RS_muldiv; j = j + 1) begin 
             if(MD_counter_run == 0 && MD_updated == 0 && MD_RS_busy[j]==1 && MD_RS_src1[j]==0 && MD_RS_src2[j]==0 ) // send to execution if values available
                 begin
                 MD_src1 <= MD_RS_value1[j];
                 MD_src2 <= MD_RS_value2[j];
                 MD_dest <= MD_RS_dest[j];
                 MD_instr <= MD_RS_instr[j];
                 MD_instr_ID <= MD_RS_instr_ID[j];
                 MD_RS_busy[j] <= 0;
                 MD_start <= 1;
                 MD_updated <= 1;
                 end

          end
     end
    end

reg [6:0]MD_counter;
reg[31:0]MD_result;
reg MD_type;
always@(posedge clk)
begin
    if(rst==1)
    begin
        MD_counter<=0;
        MD_result<=0;
        MD_valid<=0;
        MD_counter_run<=0;
    end
    else if(MD_start==1)
    begin
        if(MD_instr==`mul)
        begin
            MD_result<=MD_src1*MD_src2;
            MD_type<=0;
        end
        else if(MD_instr==`div)
        begin
            MD_result<=MD_src1/MD_src2;
            MD_type<=1;
        end
        MD_counter<=0;
        MD_valid<=0;
        MD_counter_run<=1;
    end
    else if(MD_counter>8&&MD_type==0)
    begin
        MD_valid<=1;
        MD_counter<=0;
        MD_counter_run<=0;
    end
    else if(MD_counter>38&&MD_type==1)
    begin
        MD_valid<=1;
        MD_counter<=0;
        MD_counter_run<=0;
    end
    else if(MD_counter_run==1)
    begin
        MD_counter<=MD_counter+1;
    end
end

reg [$clog2(`no_instr)-1:0]CDB_instr_ID;
reg CDB_valid;
reg CDB_updated;
integer u;
always@(posedge clk)
begin
    if(rst==1)
    begin
    CDB_dest<=0;
    CDB_value<=0;
    CDB_instr_ID<=0;
    CDB_valid<=0;
    end
    else
    begin
    if(LS_valid==1)
    begin
        CDB_dest<=LS_dest;
        CDB_value<=LS_result;
        CDB_instr_ID<=LS_instr_ID;
        CDB_valid<=1;
        LS_valid=0;
    end
    else if(AS_valid==1)
    begin
        CDB_dest<=AS_dest;
        CDB_value<=AS_result;
        CDB_instr_ID<=AS_instr_ID;
        CDB_valid<=1;
        AS_valid=0;
    end
    else if(MD_valid==1)
    begin
        CDB_dest<=MD_dest;
        CDB_value<=MD_result;
        CDB_instr_ID<=MD_instr_ID;
        CDB_valid<=1;
        MD_valid=0;
    end
    else if(Branch_valid==1)
    begin
        CDB_dest<=4'b1111;
        CDB_value<=Branch_result;
        CDB_instr_ID<=B_instr_ID;
        CDB_valid<=1;
        Branch_valid=0;
        
    end
    end
end

integer i;
always@(posedge clk)
begin
    if(rst==1)
    begin
        ROB_issue<=1;
        ROB_commit<=1;
        for(i=1;i<=`no_ROB;i=i+1)
        begin
            ROB_instr_ID[i]<=0;
            ROB_dest[i]<=0;
            ROB_valid[i]<=0;
            ROB_value[i] <= 32'hxxxxxxxx;
        end
    end
    else
    begin
        for(i=1;i<=`no_ROB;i=i+1)
        begin
            if(ROB_instr_ID[i]==`no_instr)
            done<=1;
            if(CDB_valid==1&&CDB_instr_ID==ROB_instr_ID[i])
            begin
                ROB_value[i]<=CDB_value;
                if(ROB_dest[i]==4'b1111&&CDB_value==1)
                ROB_valid[i]<=0;
                else
                ROB_valid[i]<=1;
                CDB_valid=0;///
            end
        end
    
    if(ROB_valid[ROB_commit]==1)
    begin
        ARF[ROB_dest[ROB_commit]]<=ROB_value[ROB_commit];
        ROB_valid[ROB_commit]<=0;
        ROB_commit<=ROB_commit+1;
    end
    end
end
 
endmodule
