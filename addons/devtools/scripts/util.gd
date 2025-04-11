class_name DEV_Util extends RefCounted


const EXACT_MATCH_BONUS          := 1000
const PREFIX_MATCH_BONUS         := 500  # Input is a prefix of the candidate
const SUBSTRING_MATCH_BONUS      := 200  # Input is found within the candidate (not at the start)
const FUZZY_MATCH_BONUS_PER_CHAR := 50   # For matches allowing typos/skipped chars
const CASE_MATCH_BONUS           := 10   # Extra points if case matches exactly
const HISTORY_BOOST_FACTOR       := 1.5  # Multiplier for items found in recent history
const CONSECUTIVE_CHAR_BONUS     := 20   # Bonus for each consecutive matching char in fuzzy/substring


static var cleanup_regex := RegEx.create_from_string('[^\\w\\s]')


static func cleanup_string(text: String) -> String:
	return cleanup_regex.sub(text.to_lower(), ' ', true).strip_edges()


static func get_default_window_size() -> Vector2i:
	var window_width := ProjectSettings.get_setting_with_override(&"display/window/size/window_width_override")
	var window_height := ProjectSettings.get_setting_with_override(&"display/window/size/window_height_override")
	
	if not window_width:
		window_width = ProjectSettings.get_setting_with_override(&"display/window/size/viewport_width")
	
	if not window_height:
		window_height = ProjectSettings.get_setting_with_override(&"display/window/size/viewport_height")
	
	return Vector2i(window_width, window_height)


static func calculate_score(candidate_name: String, user_input: String, command_history: Array = []) -> float:
	var base_score: float = 0.0

	if user_input.is_empty(): # No input, no score (or maybe score history?)
		# Optionally return a small base score for history items even with empty input?
		return 0.0

	# --- Basic Match Scoring ---
	if candidate_name == user_input:
		base_score = EXACT_MATCH_BONUS
	elif candidate_name.begins_with(user_input):
		base_score = PREFIX_MATCH_BONUS
		# Optional bonus: score higher if input is closer to full candidate length
		# var length_ratio = float(user_input.length()) / candidate_name.length()
		# base_score += length_ratio * 50 # Example bonus
	elif candidate_name.find(user_input) != -1:
		base_score = SUBSTRING_MATCH_BONUS
		# Optional penalty: Reduce score if match starts later in the string
		# var match_pos = candidate_name_lower.find(user_input_lower)
		# base_score -= match_pos * 5 # Example penalty
	else:
		# Try Fuzzy Match (Simplified - score based on matching chars in order)
		# Real fuzzy matching (like Levenshtein distance) is more complex.
		var fuzzy_score: float = calculate_fuzzy_score(candidate_name, user_input)
		if fuzzy_score > 0:
			# Ensure fuzzy doesn't overwrite a better match type unless it's higher
			base_score = max(base_score, fuzzy_score)
	
	# If no match found yet, return 0
	if base_score == 0.0:
		return 0.0
	
	# --- Refinements & Boosts ---
	var final_score: float = base_score
	
	## Type Weighting
	#var type_multiplier: float = 1.0
	#final_score *= type_multiplier
	
	# History Boost
	if candidate_name in command_history:
		# Could use frequency/recency from history for a more nuanced boost
		final_score *= HISTORY_BOOST_FACTOR
	
	# (Optional) Consecutive Character Bonus was partly included in fuzzy calc
	
	return final_score


static func calculate_fuzzy_score(candidate_lower: String, user_input_lower: String) -> float:
	if user_input_lower.is_empty(): return 0.0
	
	var score: float = 0.0
	var last_index: int = -1
	var consecutive_count: int = 0
	
	for i in range(user_input_lower.length()):
		var char_input = user_input_lower[i]
		# Find the next occurrence of char_input after last_index
		var found_index = candidate_lower.find(char_input, last_index + 1)
		
		if found_index != -1:
			score += FUZZY_MATCH_BONUS_PER_CHAR
			# Bonus for consecutive characters
			if found_index == last_index + 1:
				consecutive_count += 1
			else:
				# Add bonus for the previous run of consecutive chars (if any)
				if consecutive_count > 0:
					score += (consecutive_count * CONSECUTIVE_CHAR_BONUS)
				consecutive_count = 0 # Reset count for the new non-consecutive char
			
			last_index = found_index
		else:
			# Character not found in order, this is not a valid fuzzy match
			# according to this simple algorithm.
			return 0.0
	
	# Add bonus for the final run of consecutive chars (if any)
	if consecutive_count > 0:
		score += (consecutive_count * CONSECUTIVE_CHAR_BONUS)
	
	return score
