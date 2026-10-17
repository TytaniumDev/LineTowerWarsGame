class_name WaveDef
extends Resource
## The neutral creeps every player faces in one round. Groups spawn in list order.

@export var entries: Array[WaveEntry] = []


## Every creep in the wave, in spawn order.
func creeps() -> Array[CreepDef]:
	var result: Array[CreepDef] = []
	for entry: WaveEntry in entries:
		for i: int in entry.count:
			result.append(entry.creep)
	return result


func validate() -> PackedStringArray:
	var errors := PackedStringArray()
	for entry: WaveEntry in entries:
		if entry == null or entry.creep == null:
			errors.append("wave has an entry without a creep")
		elif entry.count <= 0:
			errors.append("wave entry counts must be positive")
	return errors
