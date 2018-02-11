(* (C) 2006-2010 Citrix Systems Inc.
 *
 * This program is free software; you can redistribute it and/or modify
 * it under the terms of the GNU Lesser General Public License as published
 * by the Free Software Foundation; version 2.1 only. with the special
 * exception on linking described in file LICENSE.
 *
 * This program is distributed in the hope that it will be useful,
 * but WITHOUT ANY WARRANTY; without even the implied warranty of
 * MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
 * GNU Lesser General Public License for more details.
*)

module D = Debug.Make(struct let name="license" end)
open D

(* Features and restrictions *)

type feature =
  | VLAN
  | QoS
  | Shared_storage
  | Netapp
  | Equalogic
  | Pooling
  | HA
  | Marathon
  | Email
  | Performance
  | WLB
  | RBAC
  | DMC
  | Checkpoint
  | CPU_masking
  | Connection
  | No_platform_filter
  | No_nag_dialog
  | VMPR
  | VMSS
  | IntelliCache
  | GPU
  | DR
  | VIF_locking
  | Storage_motion
  | VGPU
  | Integrated_GPU
  | VSS
  | Guest_agent_auto_update
  | PCI_device_for_auto_update
  | Xen_motion
  | Guest_ip_setting
  | AD
  | Ssl_legacy_switch
  | Nested_virt
  | Live_patching
  | Live_set_vcpus
  | PVS_proxy
  | IGMP_snooping
  | RPU
  | Pool_size
  | CBT
  | USB_passthrough
[@@deriving rpc]

type orientation = Positive | Negative

let keys_of_features =
  [
    VLAN, ("restrict_vlan", Positive, "VLAN");
    QoS, ("restrict_qos", Positive, "QoS");
    Shared_storage, ("restrict_pool_attached_storage", Positive, "SStorage");
    Netapp, ("restrict_netapp", Positive, "NTAP");
    Equalogic, ("restrict_equalogic", Positive, "EQL");
    Pooling, ("restrict_pooling", Positive, "Pool");
    HA, ("enable_xha", Positive, "XHA");
    Marathon, ("restrict_marathon", Positive, "MTC");
    Email, ("restrict_email_alerting", Positive, "email");
    Performance, ("restrict_historical_performance", Positive, "perf");
    WLB, ("restrict_wlb", Positive, "WLB");
    RBAC, ("restrict_rbac", Positive, "RBAC");
    DMC, ("restrict_dmc", Positive, "DMC");
    Checkpoint, ("restrict_checkpoint", Positive, "chpt");
    CPU_masking, ("restrict_cpu_masking", Positive, "Mask");
    Connection, ("restrict_connection", Positive, "Cnx");
    No_platform_filter, ("platform_filter", Positive, "Plat");
    No_nag_dialog, ("regular_nag_dialog", Positive, "nonag");
    VMPR, ("restrict_vmpr", Positive, "VMPR");
    VMSS, ("restrict_vmss", Positive, "VMSS");
    IntelliCache, ("restrict_intellicache", Positive, "IntelliCache");
    GPU, ("restrict_gpu", Positive, "GPU");
    DR, ("restrict_dr", Positive, "DR");
    VIF_locking, ("restrict_vif_locking", Positive, "VIFLock");
    Storage_motion, ("restrict_storage_xen_motion", Positive, "SXM");
    VGPU, ("restrict_vgpu", Positive, "vGPU");
    Integrated_GPU, ("restrict_integrated_gpu_passthrough", Positive, "iGPU");
    VSS, ("restrict_vss", Positive, "VSS");
    Guest_agent_auto_update, ("restrict_guest_agent_auto_update", Positive, "GAAU");
    PCI_device_for_auto_update, ("restrict_pci_device_for_auto_update", Positive, "PciAU");
    Xen_motion, ("restrict_xen_motion", Positive, "XenMotion");
    Guest_ip_setting, ("restrict_guest_ip_setting", Positive, "GuestIP");
    AD, ("restrict_ad", Positive, "AD");
    Ssl_legacy_switch, ("restrict_ssl_legacy_switch", Positive, "Ssl_legacy_switch");
    Nested_virt, ("restrict_nested_virt", Positive, "Nested_virt");
    Live_patching, ("restrict_live_patching", Positive, "Live_patching");
    Live_set_vcpus, ("restrict_set_vcpus_number_live", Positive, "Live_set_vcpus");
    PVS_proxy, ("restrict_pvs_proxy", Positive, "PVS_proxy");
    IGMP_snooping, ("restrict_igmp_snooping", Positive, "IGMP_snooping");
    RPU, ("restrict_rpu", Positive, "RPU");
    Pool_size, ("restrict_pool_size", Positive, "Pool_size");
    CBT, ("restrict_cbt", Positive, "CBT");
    USB_passthrough, ("restrict_usb_passthrough", Positive, "USB_passthrough");
  ]

(* A list of features that must be considered "enabled" by `of_assoc_list`
   if the feature string is missing from the list. These are existing features
   that have been recently restricted, and which we want to remain enabled during
   a rolling pool upgrade. *)
let enabled_when_unknown = [Xen_motion; AD]

let name_of_feature f =
  rpc_of_feature f |> Rpc.string_of_rpc

let string_of_feature f =
  let str, o, _ = List.assoc f keys_of_features in
  str, o

let feature_of_string str =
  let f, (_, o, _) = List.find (fun (_, (k, _, _)) -> str = k) keys_of_features in
  f, o

let tag_of_feature f =
  let _, _, tag = List.assoc f keys_of_features in
  tag

let all_features =
  List.map (fun (f, _) -> f) keys_of_features

let to_compact_string (s: feature list) =
  let get_tag f =
    let tag = tag_of_feature f in
    if List.mem f s then
      tag
    else
      String.make (String.length tag) ' '
  in
  let tags = List.map get_tag all_features in
  String.concat " " tags

let to_assoc_list (s: feature list) =
  let get_map f =
    let str, o = string_of_feature f in
    let switch = List.mem f s in
    let switch = string_of_bool (if o = Positive then switch else not switch) in
    str, switch
  in
  List.map get_map all_features

let of_assoc_list l =
  let get_feature f =
    try
      let str, o = string_of_feature f in
      let v = bool_of_string (List.assoc str l) in
      let v = if o = Positive then v else not v in
      if v then Some f else None
    with _ ->
      if List.mem f enabled_when_unknown then Some f else None
  in
  (* Stdext.Listext.List.filter_map get_feature all_features *)
  List.fold_right (fun f acc ->
    match get_feature f with
    | Some v -> v :: acc
    | None -> acc) all_features []
