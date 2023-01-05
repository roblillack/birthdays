type birthday = { name : string; year : int option; month : int; day : int }

let today =
  let tm = Unix.localtime (Unix.time ()) in
  {
    name = "\x1b[1m*** TODAY ***\x1b[m";
    year = Some (tm.tm_year + 1900);
    month = tm.tm_mon + 1;
    day = tm.tm_mday;
  }

let birthday_of_string str =
  let l = String.split_on_char ' ' str in
  if List.length l < 4 then None
  else
    let y = try Some (int_of_string (List.nth l 0)) with Failure _ -> None in
    try
      Some
        {
          year = y;
          month = int_of_string (List.nth l 1);
          day = int_of_string (List.nth l 2);
          name = String.concat " " (List.tl (List.tl (List.tl l)));
        }
    with Failure _ -> None

let string_of_birthday bday =
  match bday.year with
  | Some x ->
      let thisyear = (Unix.localtime (Unix.time ())).tm_year + 1900 in
      if thisyear == x then
        Printf.sprintf "%02d-%02d-%02d %s" x bday.month bday.day bday.name
      else
        Printf.sprintf "%02d-%02d-%02d %s (%d)" x bday.month bday.day bday.name
          (thisyear - x)
  | None -> Printf.sprintf "xxxx-%02d-%02d %s" bday.month bday.day bday.name

let read_file file_name =
  let res = ref [] in
  let ch = open_in file_name in
  (try
     while true do
       res := !res @ [ input_line ch ]
     done
   with End_of_file -> close_in ch);
  !res

let compare_dates a b =
  let m = a.month - b.month in
  if m != 0 then m else a.day - b.day

let index pred list =
  let rec f pred lst c =
    match lst with
    | [] -> -1
    | hd :: tl -> if pred hd then c else f pred tl (c + 1)
  in
  f pred list 0

let birthday_equal a b =
  a.name == b.name && a.year == b.year && a.month == b.month && a.day == b.day

let sort_dates l = List.sort compare_dates l

let main () =
  let birthdays =
    read_file (Printf.sprintf "%s/birthdays" (Sys.getenv "HOME"))
    |> List.filter_map birthday_of_string
    |> List.cons today |> sort_dates
  in
  let today_index = index (birthday_equal today) birthdays in

  birthdays
  |> List.iteri (fun idx bday ->
         if idx >= today_index - 5 && idx <= today_index + 8 then
           Printf.printf "%s%s\n"
             (if idx == today_index then "\x1b[7m" else "")
             (string_of_birthday bday)
         else ());
  exit 0
;;

main ()
