class_name CoinJar
extends RefCounted
## PZ-101, the Coin Jar: sort spilled coins into piles of exactly 50 cents.
## No timer and no penalty. Too much in a pile just tips it back out.

const TARGET := 50
const DENOMS := [50, 20, 10, 5, 1]
## 200 cents in all, so four piles. Several splits work.
const JAR := {50: 1, 20: 3, 10: 7, 5: 3, 1: 5}

var remaining := {}
var pile: Array[int] = []
var piles_done := 0
var wrong := 0


func _init() -> void:
	repour()


func repour() -> void:
	remaining = JAR.duplicate()
	pile.clear()
	piles_done = 0


func pile_total() -> int:
	var t := 0
	for c in pile:
		t += c
	return t


func piles_needed() -> int:
	var t := 0
	for v: int in JAR:
		t += v * int(JAR[v])
	return t / TARGET


func is_solved() -> bool:
	return piles_done == piles_needed()


## Adds a coin to the pile. Returns "pile" (a pile of 50 finished), "solved",
## "over" (too much, the pile went back), "added", or "none" (no coins left of that kind).
func add(value: int) -> String:
	if int(remaining.get(value, 0)) <= 0:
		return "none"
	remaining[value] = int(remaining[value]) - 1
	pile.append(value)
	var t := pile_total()
	if t > TARGET:
		take_back_pile()
		wrong += 1
		return "over"
	if t == TARGET:
		pile.clear()
		piles_done += 1
		return "solved" if is_solved() else "pile"
	return "added"


func take_back_pile() -> void:
	for c in pile:
		remaining[c] = int(remaining[c]) + 1
	pile.clear()


func undo_last() -> void:
	if not pile.is_empty():
		var c: int = pile.pop_back()
		remaining[c] = int(remaining[c]) + 1


## True when the coins left (plus the current pile) can still make fifties.
func still_possible() -> bool:
	var coins: Array[int] = []
	for v: int in DENOMS:
		for i in int(remaining.get(v, 0)):
			coins.append(v)
	return _can_fill(coins, [pile_total()] + _zeros(piles_needed() - piles_done - 1), 0)


static func _zeros(n: int) -> Array:
	var a := []
	for i in maxi(0, n):
		a.append(0)
	return a


static func _can_fill(coins: Array[int], bins: Array, i: int) -> bool:
	if i == coins.size():
		for b: int in bins:
			if b != TARGET:
				return false
		return true
	var tried := {}
	for b in bins.size():
		if tried.has(bins[b]) or int(bins[b]) + coins[i] > TARGET:
			continue
		tried[bins[b]] = true
		bins[b] = int(bins[b]) + coins[i]
		var ok := _can_fill(coins, bins, i + 1)
		bins[b] = int(bins[b]) - coins[i]
		if ok:
			return true
	return false
