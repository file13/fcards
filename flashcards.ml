open Core.Std

module Card = struct
  type t = {
    mutable front   : string;
    mutable back    : string;
  }
  let front  t = t.front
  let back   t = t.back
  let to_string t = t.front ^ " = " ^ t.back
  let set_front t text = t.front <- text
  let set_back  t text = t.back  <- text
  let create front back = {front; back}
  let reverse t = 
    let f_tmp = t.front in
    t.front <- t.back;
    t.back <- f_tmp
end        

module Deck = struct
  type t = {
    mutable name      : string;
    mutable cards     : Card.t list;
    mutable all_cards : Card.t list;
    mutable correct   : int;
    mutable incorrect : int;
    mutable missed    : (Card.t * int) list;
    mutable backs     : string list;
  }

  let name      t = t.name
  let cards     t = t.cards
  let correct   t = t.correct
  let incorrect t = t.incorrect
  let missed    t = t.missed

  let all_backs cards = List.map cards ~f:Card.back

  let create name cards =
    {name; 
     cards = cards;
     all_cards = cards;
     correct = 0;
     incorrect = 0;
     missed = [];
     backs = all_backs cards}

  let update_backs deck =
    deck.backs <- all_backs deck.all_cards

  let add_card deck card =
    deck.cards <- card :: deck.cards;
    deck.all_cards <- card :: deck.all_cards;
    update_backs deck

  let reset_score deck =
    deck.correct   <- 0;
    deck.incorrect <- 0

  let shuffle deck =
    deck.cards <- List.permute deck.cards

  let reset deck =
    reset_score deck;
    deck.cards <- deck.all_cards;
    update_backs deck;
    shuffle deck

  let reverse deck = 
    List.iter deck.cards ~f:Card.reverse;
    update_backs deck

  let add_missed deck card =
    match List.Assoc.find deck.missed card with
    | None   -> deck.missed <- List.Assoc.add deck.missed card 1
    | Some n -> deck.missed <- List.Assoc.add deck.missed card (n + 1)

  (* returns the total number of missed cards *)
  let total_missed deck =
    List.fold deck.missed ~init:0 ~f:(fun sum x -> sum + snd x)

  let deck_size deck = List.length deck.all_cards

  let percentage total number = 
    let t = Float.of_int total in
    let n = Float.of_int number in
    ((t -. n) /. t) *. 100.

  (*    let score deck =
        let missed = total_missed deck in
        let size = deck_size deck in
        sprintf "Score: %.0f%% -> Missed %d of %d\n" 
                (percentage size missed) missed size
  *)

  (* if correct, removes the card, increments correct *)
  let correct_answer deck =
    match List.length deck.cards with
    | 0 -> ()
    | _ -> 
      deck.correct <- deck.correct + 1;
      deck.cards <- List.tl_exn deck.cards

  (* if incorrect, moves card to back, increments missed *)
  let incorrect_answer deck card =
    match List.length deck.cards with
    | 0 -> ()
    | _ ->
      deck.incorrect <- deck.incorrect + 1;
      add_missed deck card;
      deck.cards <- 
        List.append (List.tl_exn deck.cards) 
          ((List.hd_exn deck.cards) :: [])

  (** This exception is called by list_index_exn. *)        
  exception List_item_not_found

  (** Returns the index of an item in a list. 
      Raises List_item_not_found if the item is not in the list. *)
  let list_index_exn item xs =
    let rec loop count lst =
      match lst with
      | [] -> raise List_item_not_found
      | hd::tl ->
        if hd = item then count
        else              loop (count + 1) tl
    in
    loop 0 xs

  let has_multiple_choices deck n =
    List.length deck.all_cards >= n + 1

  (** This exception is called by multiple_choices_exn. *)
  exception Not_enough_multiple_choices


  let multiple_choices_exn deck back n =
    (* make sure there's enough total cards *)
    if not (has_multiple_choices deck n) then
      raise Not_enough_multiple_choices
    else
      (* remove the back, take n, re-add back, permute *)
      let choices = 
        (List.permute 
           (back :: 
            (List.take 
               (List.filter deck.backs ~f: (fun x -> x <> back)) 
               (n - 1)))) 
      in
      (choices, list_index_exn back choices)

  let multiple_choices deck back n =
    (* make sure there's enough total cards *)
    match has_multiple_choices deck n with
    | true -> 
      let choices = 
        (List.permute 
           (back :: 
            (List.take 
               (List.filter deck.backs ~f: (fun x -> x <> back)) 
               (n - 1)))) 
      in
      Some (choices, list_index_exn back choices)
    | false -> None

  (** This sexception is called by top_card_exn. *)
  exception No_more_cards

  let top_card_exn ?(multiple_choices=0) deck =
    match deck.cards with
    | []   -> raise No_more_cards
    | x::_ -> 
      if multiple_choices = 0 then
        (x,([],0))
      else
        (x, multiple_choices_exn deck (Card.back x) multiple_choices)

  let top_card ?(choices=0) deck =
    match deck.cards with
    | []    -> None
    | hd::_ ->
      match choices with
      | 0 -> Some (hd,([],0))
      | _ ->
        match multiple_choices deck (Card.back hd) choices with
        | Some r -> Some (hd, r)
        | None   -> None

  (* load a simple text file seperated by one "|" per line *)
  let load_simple_deck filename =
    In_channel.with_file filename ~f:(fun file ->
        let cards = 
          In_channel.fold_lines file ~init:[] ~f:(fun list line ->
              let str = String.split_on_chars line ~on:['|'] in
              match List.length str with
              | 2 -> Card.create 
                       (List.hd_exn str) (List.nth_exn str 1) :: list
              | _ -> list)
        in
        create filename (List.rev cards)) 
end

                (*
let main () = ()

(* Tests *)
let test_card _ =
  let c = Card.create "Archie" "Troll" in
  assert_equal (Card.front c) "Archie";
  assert_equal (Card.back c) "Troll";
  Card.set_front c "Fred";
  Card.set_back c "Jones";
  Card.reverse c;
  assert_equal (Card.front c) "Jones";
  assert_equal (Card.back c) "Fred"

(* Run tests *)
let suite = 
  "Tests" >::: 
    ["test_card" >:: test_card
    ;
    ]
let _ = run_test_tt_main suite

if !Sys.interactive then () else main ()
                 *)
