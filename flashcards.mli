(** This is a flashcard library for Ocaml. 
    It's purpose was to be used in a
    (wait for it) flashcard program. 
    By keeping the library separate, we'll be able
    to use the same library for both a command line and GUI version.

    This library contains two modules, 
    one for an individual "two-sided" flashcard,
    and one for a deck of flashcards. 

    @author Michael J. Rossi

*)

(** This module covers a single flashcard. 
    This small library contains the usual accessing and setting functions
    you use to manipulate a flashcard.

    The code is trivial and shouldn't be difficult to understand. *)
module Card : 
sig 
  (** A [Card.t] contains a front and a back. *)
  type t = { 
    mutable front : string; 
    mutable back  : string; 
  }

  val front : t -> string
  val back  : t -> string
  val to_string : t -> string
  val set_front : t -> string -> unit
  val set_back  : t -> string -> unit
  val create : string -> string -> t

  (** Reverse or swap the front and back values. *)
  val reverse : t -> unit
  (**  This is often used with flashcards for foreign languages where
       one wants to practice with say, English to Latin and then 
       Latin to English.
       This also let's you play "Jeopardy." *)

end

(** This module covers a deck of numerous flashcards. It also contains
    all the information needed for score keeping.
    In general, you'll probably only use a few of the functions.
    The most important being [load_simple_deck], [reset], [top_card], 
    [correct_answer], and [incorrect_answer]. 

    To understand the code, you'll probably want to tackle those functions
    in that order. But the general idea is that you load a deck, reset it,
    and call [top_card] to get the next card along with the 
    multiple choices
    (if any). After you check the results, you then call [correct_answer]
    or [incorrect_answer] as appropriate. If it's correct, it'll remove it
    from the deck and update the score. If it's incorrect, it'll put
    that card on the back of the deck and update the score (and missed card
    list). Regardless of the front end, this will be the normal way
    of using this library.

*)  
module Deck :
sig
  (** A [Deck.t] not only contains a deck of individual cards, but
      contains all the tools necessary for keeping score and generating
      multiple choice options. As such, we'll keep two instances of a
      given deck. The full original deck which will be used for generating 
      restarting a deck, 
      and a list which will shrink as we remove cards. We'll also keep
      a tuple list of missed cards (the card missed and how many times it
      was missed) along with a list of card backs which we'll use to
      generate multiple choices. *)
  type t = {
    mutable name : string;
    mutable cards : Card.t list;
    mutable all_cards : Card.t list;
    mutable correct : int;
    mutable incorrect : int;
    mutable missed : (Card.t * int) list;
    mutable backs : string list;
  }

  (** The name of the deck. Currently it will be the name of the text 
      file the deck was loaded from. *)
  val name : t -> string

  (** The list of current cards. This list will shrink each time a
      card is answered correctly. *)
  val cards : t -> Card.t list

  (** Returns the number of correct cards. *)
  val correct : t -> int

  (** Returns the number of correct cards. *)
  val incorrect : t -> int

  (** Returns a list of all the missed cards and how many times
      they were missed. *)
  val missed : t -> (Card.t * int) list

  (** Returns a list of all of the card backs in the deck. Used
      for generating multiple choices. *)
  val all_backs : Card.t list -> string list

  (** Returns a new [Deck.t] with a given name and list of cards. 
      Generally not used directly, but by [load_simple_deck]. *)
  val create : string -> Card.t list -> t

  (** Generates the [all_backs]. *)
  val update_backs : t -> unit

  (** Adds a card to the deck. Note that this does not update any
      other fields, so you'll probably need to call [reset] once you're done
      adding cards. *)
  val add_card : t -> Card.t -> unit

  (** Resets the score. *)
  val reset_score : t -> unit

  (** Shuffles the [Deck.t.cards]. *)
  val shuffle : t -> unit

  (** Resets a loaded deck back to it's starting state. 
      This resets the score, restarts and shuffles the deck, and 
      regenerates the backs. *)
  val reset : t -> unit

  (** Reverses all the cards in the deck calling [Card.reverse]. 
      This also automatically updates the backs. *)
  val reverse : t -> unit

  (** Adds a missed card to the missed list or else increments the 
      times missed if it's already been missed before. *)
  val add_missed : t -> Card.t -> unit

  (** Returns the total number of missed cards *)
  val total_missed : t -> int

  (** Returns the current number of cards left in the deck. *)
  val deck_size : t -> int

  (** Returns the percentage score. *)
  val percentage : int -> int -> float

  (** Called every time one gets an answer correct. This performs
      the upkeep of removing that card and updating the score. *)
  val correct_answer : t -> unit

  (** Called every time one gets an answer incorrect. This performs
      the upkeep of adding a missed card, updating the score, and moving
      the missed card to the back of the deck. *)
  val incorrect_answer : t -> Card.t -> unit

  (** Predicate to determine if the deck can generate N number of 
      multiple choices. *)
  val has_multiple_choices : t -> int -> bool

  (** This exception is called by [multiple_choices_exn]. *)
  exception Not_enough_multiple_choices

  (** The exception throwing version of [multiple_choices]. 
      Generally, you'll want [multiple_choices], not this.*)
  val multiple_choices_exn : t -> string -> int -> string list * int

  (** Returns an option (i.e. [Some] or [None]), if [Some], a tuple 
      containing a of random multiple choices and the int location of
      the correct answer in the list given the current top card. *)
  val multiple_choices : t -> string -> int -> (string list * int) option
  (** Example: If we call "[multiple_choices deck 4]" on a deck
      that has 10 cards, this will return a list of 3 randomly generated
      multiple choices along with the correct answer for the top card. It
      also returns the position in the list where the correct answer is.
      So if "[multiple_choices deck 4]" returns the number 2, it means
      the correct multiple choice answer is 2 and thus, the third item
      in the list (since we start from 0). *)

  (** This exception is called by [top_card_exn]. *)
  exception No_more_cards

  (** The exception throwing version of [top_card]. 
      Returns a tuple of the top card, another tuple containing 
      a string list filled with the multiple choices, and the location
      of the correct answer in the list of choices.*)
  val top_card_exn :
    ?multiple_choices:int -> t -> Card.t * (string list * int)

  (** Like [top_card_exn], except the results are wrapped in
      an [Option]. *)
  val top_card : ?choices:int -> t
    -> (Card.t * (string list * int)) option

  (** Loads a simple card deck file name and returns a populated
      Deck.t. Note, this does not call reset. *)
  val load_simple_deck : string -> t
  (** The format for a "simple deck" is a text file where 
      each line represents a new card. 
      Each card is then separated by the "|" character.
      The part before the "|" is the front, the part after, the back.
      For example, a simple three card deck file consists of a three 
      line text file that looks like this.

      {v
Archibald Thurston Buxton McButterpans Cross|Troll
3 * 3|9
Ho logos|the word
v}

      In this example, the first line will be the first card. 
      The front of the first card will be 
      Archibald Thurston Buxton McButterpans Cross and the 
      back will be Troll. 
      The front of the second card will be 3 * 3 and the back 9. 
      Ditto for the third card whose front is Ho logos and back the word.
  *)


end
