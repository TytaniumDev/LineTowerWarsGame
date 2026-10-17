class_name OpponentPicker
extends RefCounted
## Picks an opponent snapshot (D8): same round number, preferring a similar record.
##
## With nothing saved for the round, it falls back to the latest earlier round, so an
## empty pool still finds the strongest available opponent.


## A snapshot for a player in `round_number` with `wins` and `losses`, or null if
## `pool` has nothing for this round or earlier.
static func pick(
	pool: Array[Snapshot], round_number: int, wins: int, losses: int, rng: SimRng
) -> Snapshot:
	var best_round := 0
	for snapshot: Snapshot in pool:
		if snapshot.round_number <= round_number:
			best_round = maxi(best_round, snapshot.round_number)
	if best_round == 0:
		return null
	var best_score := -1
	var closest: Array[Snapshot] = []
	for snapshot: Snapshot in pool:
		if snapshot.round_number != best_round:
			continue
		var score := absi(snapshot.wins - wins) + absi(snapshot.losses - losses)
		if best_score < 0 or score < best_score:
			best_score = score
			closest.clear()
		if score == best_score:
			closest.append(snapshot)
	return closest[rng.range_int(0, closest.size() - 1)]
