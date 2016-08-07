// Copyright 2016 Tudor Timisescu (verificationgentleman.com)
//
// Licensed under the Apache License, Version 2.0 (the "License");
// you may not use this file except in compliance with the License.
// You may obtain a copy of the License at
//
//     http://www.apache.org/licenses/LICENSE-2.0
//
// Unless required by applicable law or agreed to in writing, software
// distributed under the License is distributed on an "AS IS" BASIS,
// WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
// See the License for the specific language governing permissions and
// limitations under the License.


class master_driver extends uvm_driver #(sequence_item);
  virtual vgm_wb_master_interface intf;


  virtual task run_phase(uvm_phase phase);
    forever begin
      seq_item_port.get_next_item(req);
      drive();
      seq_item_port.item_done();
    end
  endtask


  virtual protected task drive();
    repeat (req.delay)
      @(posedge intf.CLK_I);

    intf.CYC_O <= 1;
    intf.STB_O <= 1;
    intf.WE_O <= req.direction;
    intf.ADR_O <= req.address;

    @(posedge intf.CLK_I iff intf.ACK_I);
    intf.CYC_O <= 0;
    intf.STB_O <= 0;
  endtask


  function new(string name, uvm_component parent);
    super.new(name, parent);
  endfunction

  `uvm_component_utils(vgm_wb::master_driver)
endclass
