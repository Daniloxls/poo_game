class_name ConsoleSuggestion
extends RefCounted
## Uma sugestão do autocomplete do console.

var label := ""
var detail := ""
var enabled := true
var result_text := ""   # a linha inteira do console depois de aceitar


static func make(p_label: String, p_detail: String, p_enabled: bool, p_result: String) -> ConsoleSuggestion:
	var s := ConsoleSuggestion.new()
	s.label = p_label
	s.detail = p_detail
	s.enabled = p_enabled
	s.result_text = p_result
	return s
