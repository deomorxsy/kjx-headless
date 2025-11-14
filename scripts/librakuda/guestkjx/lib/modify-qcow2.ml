open Guestfs

let () =
    (* initialize guestfs handle *)
    let g = create () in
    (* Path to the qcow2 image *)
    let qcow2_image = "disk.qcow2" in
    Printf.printf "Opening image: %s\n" qcow2_image;

    (* add the disk image *)
    add_drive_opts g qcow2_image ~format:"qcow2" ~readonly:false;

    (* launch guestfs *)
    launch g;

    (* list partitions *)
    let partitions = list_partitions g in
    Printf.printf "Partitions found: %s\n" (String.concat ", " partitions);

    (* mount the first partition *)
    (match partitions with
    | [] -> Printf.printf "No partitions found.\n"
    | p :: _ ->
            mount g p "/";
            Printf.printf "MOunted %s at /\n" p;
            (* list files in root *)
            let files = ls g "/" in
            Printf.printf "Root directory contents: %s\n" (String.concat ", " files);

            (* create a new file inside the image *)
            let filename = "/test_file.txt" in
            write g filename "hello from ocaml!";
            Printf.printf "Created file: %s\n" filename;

            (* unmount and close *)
            umount g "/";
            Printf.printf "Unmounted %s\n" p;)

    close g;
    Printf.printf "Done.\n"
