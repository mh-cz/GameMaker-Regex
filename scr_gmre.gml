enum e_gmre_rule { CHARSET, STRING, LOOP }

#region FN
function gmre_match(ex, str) {
	return ex.match(str);
}

function gmre_find(ex, str, substr) {
	return ex.find(str, substr);
}

function gmre_find_all(ex, str, substr) {
	return ex.find_all(str, substr);
}

function gmre_find_pos(ex, str, substr) {
	return ex.find_pos(str, substr);
}

function gmre_find_pos_all(ex, str, substr) {
	return ex.find_pos_all(str, substr);
}

function gmre_replace(ex, str, substr) {
	return ex.replace(str, substr);
}

function gmre_replace_all(ex, str, substr_or_array) {
	return ex.replace_all(str, substr_or_array);
}

function gmre_contains(ex, str, substr) {
	return ex.find_pos(str, substr) != 0;
}
#endregion

#region EXPR CODE
function expression(expr = "", simplified = false) constructor {
	
	rules = [];
	exp_arr = [];
	exp_len = 0;
	str_arr = [];
	str_len = 0
	ok = true;
	err = "";
	current_rule = 0;
	
	if expr != "" parse(expr, simplified);
	
	static parse = function(expr, simplified = false) {
		
		if simplified expr = _unsimplify(expr);
		else expr = _escape(expr);
		
		err = "";
		ok = true;
		rules = [];
		exp_len = string_length(expr);
		exp_arr = array_create(exp_len);
		
		for(var i = 0; i < exp_len; i++) exp_arr[i] = string_char_at(expr, i+1);
			
		if !_generate_rules() return false;
		
		return true;
	}
	
	static _unsimplify = function(expr) {
		
		newexpr = "";
		collector = "";
		var l = string_length(expr);
		for(var i = 1; i <= l; i++) {
			var ch = string_char_at(expr, i);
			if ch == "*" {
				if collector != "" newexpr += collector + "|";
				collector = "";
				newexpr += "![]?";
			}
			else {
				if collector == "" collector = "|"
				collector += ch;
			}
		}
		if collector != "" newexpr += collector + "|";
		return newexpr;
	}
	
	static match = function(str) {
		
		if array_length(rules) == 0 return false;
		
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		return _apply_rules(0) == str_len ? true : false;
	}
	
	static find = function(str) {
		
		if array_length(rules) == 0 return "";
		
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		for(from = 0; from < str_len; from++) {
			var to = _apply_rules(from);
			if to == -1 continue;
			return string_copy(str, from+1, to-from);
		}
		
		return "";
	}
	
	static find_all = function(str) {
		
		if array_length(rules) == 0 return [];
		
		var arr = [];
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		for(from = 0; from < str_len; from++) {
			var to = _apply_rules(from);
			if to == -1 continue;
			array_push(arr, string_copy(str, from+1, to-from));
			from = to-1;
		}
		
		return arr;
	}	
	
	static find_pos = function(str) {
		
		if array_length(rules) == 0 return 0;
		
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		for(from = 0; from < str_len; from++) {
			var to = _apply_rules(from);
			if to == -1 continue;
			return from+1;
		}
		
		return "";
	}

	static find_pos_all = function(str) {
		
		if array_length(rules) == 0 return [];
		
		var arr = [];
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		for(from = 0; from < str_len; from++) {
			var to = _apply_rules(from);
			if to == -1 continue;
			array_push(arr, from+1);
			from = to-1;
		}
		
		return arr;
	}
	
	static replace = function(str, substr) {
		
		if array_length(rules) == 0 return str;
		substr = string(substr);
		
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		for(from = 0; from < str_len; from++) {
			var to = _apply_rules(from);
			if to == -1 continue;
			return string_insert(substr, string_delete(str, from+1, to-from), from+1);
		}
		
		return str;
	}
		
	static replace_all = function(str, substr_or_array) {
		
		if array_length(rules) == 0 return str;
		
		var arrlen = 0;
		var ai = 0;
		var is_arr = is_array(substr_or_array);
		
		if is_arr arrlen = array_length(substr_or_array);
		else substr_or_array = string(substr_or_array);
		
		var offset = 0;
		
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		for(from = 0; from < str_len; from++) {
			var to = _apply_rules(from);
			if to == -1 continue;
			
			var sub = is_arr ? substr_or_array[min(arrlen, ai++)] : substr_or_array;
			str = string_insert(sub, string_delete(str, from+1 + offset, to-from), from+1 + offset);
			from = to-1;
			offset += string_length(sub)-1 - (to-from);
		}
		
		return str;
	}
	
	static _apply_rules = function(pos) {
		
		var rlen = array_length(rules);
		for(current_rule = 0; current_rule < rlen; current_rule++) {
			
			var r = rules[current_rule];
			var rn = current_rule+1 < rlen ? rules[current_rule+1] : undefined;
			
			switch(r.type) {
				case e_gmre_rule.CHARSET:
					var result = _check_charset(r, pos, rn);
					if result == -1 return -1;
					pos = result;
					break;
				case e_gmre_rule.STRING:
					var result = _check_string(r, pos, rn);
					if result == -1 return -1;
					pos = result;
					break;
			}
		}
		
		return current_rule == rlen ? pos : -1;
	}
	
	static _skip_inf = function(r, pos, rn) {
		if r.rmax == infinity and rn != undefined and pos < str_len {
			switch(rn.type) {
				case e_gmre_rule.CHARSET:
					if _check_charset(rn, pos, undefined) != -1 return true;
					break;
				case e_gmre_rule.STRING:
					if _check_string(rn, pos, undefined) != -1 return true;
					break;
			}
		}
		return false;
	}
	
	static _check_charset = function(r, pos, rn) {
		
		var rep = 0;
		if pos >= str_len and r.rmin == 0 return pos;
		
		if !_skip_inf(r, pos, rn) and pos < str_len {
			var ch = str_arr[pos];
			while(_ch_in_charset(r, ch) xor r.negated) {
				rep++;
				pos++;
				if pos >= str_len or rep >= r.rmax or _skip_inf(r, pos, rn) break;
				ch = str_arr[pos];
			}
		}
		
		return rep >= r.rmin ? pos : -1;
	}
	
	static _ch_in_charset = function(r, ch) {
		
		var ch_ascii = ord(ch);
		var l = array_length(r.charset);
		
		for(var i = 0; i < l; i++) {
			var chrs = r.charset[i];
			if is_array(chrs) {
				if ch_ascii >= chrs[0] and ch_ascii <= chrs[1] return true;
			}
			else if ch_ascii == chrs return true;
		}
		
		return false;
	}
	
	static _check_string = function(r, pos, rn) {
		
		var l = array_length(r.str);
		if pos >= str_len and r.rmin == 0 return pos;
		if l == 0 return pos;
		
		var rep = 0;
		if !_skip_inf(r, pos, rn) and pos < str_len {
			while(_str_in_str(r, pos) xor r.negated) {
				rep++;
				pos += l;
				if pos >= str_len or rep >= r.rmax or _skip_inf(r, pos, rn) break;
			}
		}
		
		return rep >= r.rmin ? pos : -1;
	}
	
	static _str_in_str = function(r, pos) {
		
		var l = array_length(r.str);
		
		for(var i = 0; i < l; i++) {
			if pos + i >= str_len return false;
			if str_arr[pos+i] != r.str[i] return false;
		}
		return true;
	}
	
	static _generate_rules = function() {
		
		var loop = undefined;
		var loop_start = 0;
		
		for(var i = 0; i < exp_len; i++) {
			var ch = exp_arr[i];
			var chp = (i != 0 ? exp_arr[i-1] : "");
			
			switch(ch) {
				
				#region CHARSET
				case "[":
					if chp == "\\" break;
					
					var r = new _gmre_rule_(e_gmre_rule.CHARSET, chp == "!");
					var closed = false;
					var ri = i+1;
					
					while(ri < exp_len) {
						ch = exp_arr[ri];
						chp = exp_arr[ri-1];
						chpp = ri > 1 ? exp_arr[ri-2] : "";
						
						ri++;
						
						if ch == "]" and chp != "\\" {
							closed = true;
							break;	
						}
						
						array_push(r.str, ch);
					}
					
					if !closed return _error("UNCLOSED CHARSET AT: " + string(i+1), i+1);
					
					ri = _get_repeats(r, ri);
					if floor(ri) != ri return _error("REPEAT SYNTAX ERROR AT: " + string(floor(ri)+1), floor(ri)+1);						
					
					r._process_charset();
					array_push(loop == undefined ? rules : loop.rules, r);
					i = ri - 1;
					
					break;
				#endregion
				
				#region STRING
				case "|":
					if chp == "\\" break;
					
					var r = new _gmre_rule_(e_gmre_rule.STRING, chp == "!");
					var closed = false;
					var ri = i+1;
					
					while(ri < exp_len) {
						ch = exp_arr[ri];
						chp = exp_arr[ri-1];
						
						ri++;
						
						if ch == "|" and chp != "\\" {
							closed = true;
							break;	
						}
						
						array_push(r.str, ch);
					}
					
					if !closed return _error("UNCLOSED STRING AT: " + string(i+1), i+1);
					
					ri = _get_repeats(r, ri);
					if floor(ri) != ri return _error("REPEAT SYNTAX ERROR AT: " + string(floor(ri)+1), floor(ri)+1);					
					
					r._process_string();
					array_push(loop == undefined ? rules : loop.rules, r);
					i = ri - 1;
					
					break;
				#endregion
				
				#region LOOP
				case "(":
					if chp == "\\" or loop != undefined break;
					
					loop = new _gmre_rule_(e_gmre_rule.LOOP, chp == "!");
					loop_start = i;
					break;
				
				case ")":
					if chp == "\\" or loop == undefined break;
					
					array_push(rules, loop);
					loop = undefined;
					break;
				#endregion
			}
		}
		
		if loop != undefined return _error("UNCLOSED LOOP AT: " + string(loop_start), loop_start);
		
		return true;
	}
	
	static _get_repeats = function(r, ri) {
		
		var valid = true;
		var first = true;
		var mn = "";
		var mx = "";
		
		while(ri < exp_len) {
			
			var ch = exp_arr[ri];
			
			if _is_number(ch) {
				valid = true;
				if first mn += ch;
				else mx += ch;
			}
			else if ch == "?" {
				valid = true;
				if first mn = ch;
				else mx = ch;
			}
			else if ch == "-" {
				valid = false;
				first = false;
			}
			else break;
			
			ri++;
		}
		
		if !valid return ri + 0.5;
		
		if mn == "?" {
			r.rmin = 0;
			r.rmax = infinity;
		}
		else if mn != "" {
			r.rmin = real(mn);
			r.rmax = r.rmin;
		}

		if mx == "?" {
			r.rmax = infinity;
		}
		else if mx != "" {
			r.rmax = real(mx);
		}
		
		return ri;
	}
	
	static _is_number = function(ch) {
		var ascii = ord(ch);
		return ascii > 47 and ascii < 58;
	}
	
	static _is_letter = function(ch) {
		var ascii = ord(ch);
		return (ascii > 64 and ascii < 91) or (ascii > 96 and ascii < 123);
	}
	
	static _error = function(e, mark_pos = -1) {
		err = e + (mark_pos != -1 ? "\n" + string_insert("#", _arr2str(exp_arr), mark_pos) : "");
		ok = false;
		return false;
	}
	
	static _arr2str = function(arr) {
		var str = "";
		for(var i = 0, l = array_length(arr); i < l; i++) str += string(arr[i]);
		return str;
	}
	
	static _escape = function(str) {
		str = string_replace_all(str, "\\\\", "ª");
		str = string_replace_all(str, "\\(", "·¹");
		str = string_replace_all(str, "\\[", "·²");
		str = string_replace_all(str, "\\|", "·³");
		str = string_replace_all(str, "\\)", "°¹");
		str = string_replace_all(str, "\\]", "°²");
		return str;
	}
}
#endregion

#region RULE CODE
function _gmre_rule_(t, n) constructor {
	
	type = t
	negated = n;
	rmin = 1;
	rmax = 1;
	rules = [];
	charset = [];
	str = [];
	
	static _process_string = function() {
		
		var s = _unescape(_arr2str(str));
		var l = string_length(s);
		str = array_create(l);
		for(var i = 0; i < l; i++)
			str[i] = string_char_at(s, i+1);
	}
	
	static _process_charset = function() {
		
		_process_string();
		
		var len = array_length(str);
		for(var i = 0; i < len; i++) {
			var ch1 = str[i];
			
			if _is_letter(ch1) {
				var ch2 = i+1 < len ? str[i+1] : "";
				if ch2 == "-" {
					var ch3 = i+2 < len ? str[i+2] : "";
					if _is_letter(ch3) {
						if _letter_is_upper(ch1) == _letter_is_upper(ch3) {
							array_push(charset, [ord(ch1), ord(ch3)]);
						}
						else {
							array_push(charset, [ord(string_upper(ch1)), ord(string_upper(ch3))]);
							array_push(charset, [ord(string_lower(ch1)), ord(string_lower(ch3))]);
						}
						i += 2;
						continue;
					}
				}
			}
			else if _is_number(ch1) {
				var ch2 = i+1 < len ? str[i+1] : "";
				if ch2 == "-" {
					var ch3 = i+2 < len ? str[i+2] : "";
					if _is_number(ch3) {
						array_push(charset, [ord(ch1), ord(ch3)]);
						i += 2;
						continue;
					}
				}
			}
			
			array_push(charset, ord(ch1));
		}
	}
	
	static _is_number = function(ch) {
		var ascii = ord(ch);
		return ascii > 47 and ascii < 58;
	}
	
	static _is_letter = function(ch) {
		var ascii = ord(ch);
		return (ascii > 64 and ascii < 91) or (ascii > 96 and ascii < 123);
	}
	
	static _letter_is_upper = function(ch) {
		var ascii = ord(ch);
		return ascii > 64 and ascii < 91;
	}
	
	static _arr2str = function(arr) {
		var str = "";
		for(var i = 0, l = array_length(arr); i < l; i++) str += string(arr[i]);
		return str;
	}
	
	static _unescape = function(str) {
		str = string_replace_all(str, "\\", "");
		str = string_replace_all(str, "ª", "\\");
		str = string_replace_all(str, "·¹", "(");
		str = string_replace_all(str, "·²", "[");
		str = string_replace_all(str, "·³", "|");
		str = string_replace_all(str, "°¹", ")");
		str = string_replace_all(str, "°²", "]");
		return str;
	}
}
#endregion
