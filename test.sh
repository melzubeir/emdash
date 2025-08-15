#!/bin/sh
# Portable test runner (no associative arrays required)

API_URL="${API_URL:-http://localhost:3000/emdash}"

# Detect a version-aware sort if available; fall back to plain sort
if sort -V </dev/null >/dev/null 2>&1; then
  SORT_CMD='sort -V'
else
  SORT_CMD='sort'
fi

# --- Key/Value dataset (TAB-separated): key<TAB>value ---
DATA='
parenthetical_1	My sister — who never cooks — made dinner last night.
parenthetical_2	The car — a bright red convertible — caught everyone’s attention.
parenthetical_3	This book — my all-time favorite — never gets old.
parenthetical_4	We met John — our old college roommate — at the reunion.
parenthetical_5	The plan — though risky — might just work.
suddenbreak_1	I thought it was a great idea — until I heard the cost.
suddenbreak_2	We were going to leave early — but the rain kept us inside.
suddenbreak_3	She almost told him the truth — and then decided against it.
suddenbreak_4	I started walking toward the door — then stopped.
suddenbreak_5	He was about to sign the contract — when the phone rang.
appositive_1	She is an expert — a true authority in her field.
appositive_2	He’s my best friend — the person I trust most.
appositive_3	This is the real problem — the lack of communication.
appositive_4	That’s the challenge — getting everyone to agree.
appositive_5	Here’s your reward — an extra day off.
summary_1	Long nights, endless rehearsals, countless cups of coffee — all for opening night.
summary_2	Broken glass, a smashed door, missing valuables — it was clearly a break-in.
summary_3	Late trains, heavy traffic, bad weather — today was not my day.
summary_4	Jeans, T-shirts, sneakers — his wardrobe never changed.
summary_5	Pain, sweat, and hard work — that’s what built this company.
listintro_1	We need several things — bread, milk, eggs, and butter.
listintro_2	She packed everything — sunscreen, towels, snacks, and water bottles.
listintro_3	The class will cover three topics — history, geography, and culture.
listintro_4	He ordered a variety of drinks — coffee, tea, soda, and juice.
listintro_5	They brought the essentials — maps, flashlights, and first-aid kits.
interrupt_1	“I was just about to—”
interrupt_2	“If you think I’m going to—”
interrupt_3	“Wait, I didn’t mean—”
interrupt_4	“Don’t you dare—”
interrupt_5	“I was trying to say—”
dramaticpause_1	And the winner is — Michael.
dramaticpause_2	The answer to your question is — yes.
dramaticpause_3	The person behind it all was — my own brother.
dramaticpause_4	The solution is simple — work together.
dramaticpause_5	Our biggest competitor is — ourselves.
internalcommas_1	She laughed, cried, and shouted — but she never gave up.
internalcommas_2	They came early, stayed late, and worked hard — yet still missed the deadline.
internalcommas_3	He was tired, hungry, and sore — and still kept running.
internalcommas_4	The team played well, passed accurately, and defended strongly — until the final minutes.
internalcommas_5	I planned, packed, and saved — only to have the trip canceled.
namely_1	There’s one thing I can’t stand — dishonesty.
namely_2	He has one true passion — music.
namely_3	Our goal is clear — success.
namely_4	This is my greatest fear — failure.
namely_5	She only wants one thing — respect.
pauseemphasis_1	The recipe — though simple — is delicious.
pauseemphasis_2	That trip — despite the rain — was unforgettable.
pauseemphasis_3	The meeting — if it happens — could change everything.
pauseemphasis_4	Her response — as expected — was sarcastic.
pauseemphasis_5	The project — while behind schedule — will still be completed.
listinlist_1	We traveled to Paris, France; Rome, Italy; and Berlin, Germany — all in one summer.
listinlist_2	The menu included pasta, salad, and breadsticks; steak, potatoes, and vegetables — everything we could want.
listinlist_3	They visited Chicago, Illinois; Denver, Colorado; and Austin, Texas — and still had time for more.
listinlist_4	The tour covered Madrid, Spain; Lisbon, Portugal; and Dublin, Ireland — a whirlwind trip.
listinlist_5	We met clients from Tokyo, Japan; Seoul, South Korea; and Beijing, China — all in the same week.
daterange_1	Office hours are 9:00 a.m.—5:00 p.m.
daterange_2	The sale runs June 1—June 15.
daterange_3	The conference is scheduled for March 10—March 14.
daterange_4	The course is offered September—December.
daterange_5	The store is open Monday—Saturday.
attribution_1	“The best way out is always through.” — Robert Frost
attribution_2	“Do or do not, there is no try.” — Yoda
attribution_3	“Injustice anywhere is a threat to justice everywhere.” — Martin Luther King Jr.
attribution_4	“I think, therefore I am.” — René Descartes
attribution_5	“The only thing we have to fear is fear itself.” — Franklin D. Roosevelt
punchend_1	I was ready to forgive — until he laughed.
punchend_2	We almost won — if not for that last-minute mistake.
punchend_3	She looked happy — until she saw the bill.
punchend_4	He was about to say yes — when the phone rang.
punchend_5	I thought we were friends — until you lied to me.
'

echo "Running tests..."

# Print DATA, strip empty lines, sort by key, then read lines
printf "%s" "$DATA" | awk 'NF' | $SORT_CMD |
while IFS="$(printf '\t')" read -r key text; do
  # Safety: skip if no key or text
  [ -z "$key" ] && continue
  [ -z "$text" ] && continue

  echo "-----------------------------------"
  echo "Testing [$key]: $text"

  # Hit API with URL-encoded text
  response="$(curl -s -G --data-urlencode "text=$text" "$API_URL")"

  # Pretty-print JSON if jq exists AND response is valid JSON
  if command -v jq >/dev/null 2>&1 && printf '%s' "$response" | jq -e . >/dev/null 2>&1; then
    printf '%s' "$response" | jq '.original, .result'
  else
    printf '%s\n' "$response"
    if ! command -v jq >/dev/null 2>&1; then
      echo "(Install jq for better formatting)"
    fi
  fi
done

echo "-----------------------------------"
echo "Tests complete."
