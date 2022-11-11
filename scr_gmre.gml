enum e_gmre_rule { CHARSET, STRING, LOOP, CUSTOM_POS, CP_X, CP_NX, CP_CHARSET, CP_STRING }

#region GMRE

function gmre_ex_parse(ex, new_expression_string) {
	return ex.parse(new_expression_string);
}

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

#region EXPRESSION LOGIC
function expression(expr = "", simple = false) constructor {
	
	#region VAR
	rules = [];
	exp_arr = [];
	exp_len = 0;
	str_arr = [];
	str_len = 0
	ok = true;
	err = "";
	#endregion
	
	#region INPUT FUNC
	if expr != "" parse(expr, simple);
	
	static parse = function(expr, simple = false) {
		
		if simple expr = _unsimplify(expr);
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
	
	static match = function(str) {
		
		if array_length(rules) == 0 return false;
		
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		return _apply_rules(rules, 0, str_len) == str_len ? true : false;
	}
	
	static find = function(str) {
		
		if array_length(rules) == 0 return "";
		
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		for(pos = 0; pos < str_len; pos++) {
			var to = _apply_rules(rules, pos, str_len);
			if to == -1 continue;
			return string_copy(str, pos+1, to-pos);
		}
		
		return "";
	}
	
	static find_all = function(str) {
		
		if array_length(rules) == 0 return [];
		
		var arr = [];
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		for(pos = 0; pos < str_len; pos++) {
			var to = _apply_rules(rules, pos, str_len);
			if to == -1 continue;
			array_push(arr, string_copy(str, pos+1, to-pos));
			pos = to-1;
		}
		
		return arr;
	}	
	
	static find_pos = function(str) {
		
		if array_length(rules) == 0 return 0;
		
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		for(pos = 0; pos < str_len; pos++) {
			var to = _apply_rules(rules, pos, str_len);
			if to == -1 continue;
			return pos+1;
		}
		
		return "";
	}

	static find_pos_all = function(str) {
		
		if array_length(rules) == 0 return [];
		
		var arr = [];
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		for(pos = 0; pos < str_len; pos++) {
			var to = _apply_rules(rules, pos, str_len);
			if to == -1 continue;
			array_push(arr, pos+1);
			pos = to-1;
		}
		
		return arr;
	}
	
	static replace = function(str, substr) {
		
		if array_length(rules) == 0 return str;
		substr = string(substr);
		
		str_len = string_length(str);
		str_arr = array_create(str_len);
		for(var i = 0; i < str_len; i++) str_arr[i] = string_char_at(str, i+1);
		
		for(pos = 0; pos < str_len; pos++) {
			var to = _apply_rules(rules, pos, str_len);
			if to == -1 continue;
			return string_insert(substr, string_delete(str, pos+1, to-pos), pos+1);
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
		
		for(pos = 0; pos < str_len; pos++) {
			var to = _apply_rules(rules, pos, str_len);
			if to == -1 continue;
			
			var sub = is_arr ? substr_or_array[min(arrlen, ai++)] : substr_or_array;
			str = string_insert(sub, string_delete(str, pos+1 + offset, to-pos), pos+1 + offset);
			pos = to-1;
			offset += string_length(sub)-1 - (to-pos);
		}
		
		return str;
	}
	#endregion
	
	#region UNSIMPLIFY
	static _unsimplify = function(expr) {
		
		newexpr = "";
		collector = "";
		var l = string_length(expr);
		for(var i = 1; i <= l; i++) {
			var ch = string_char_at(expr, i);

			if ch == "*" and string_char_at(expr, i-1) != "\\" {
				if collector != "" newexpr += collector + "|";
				collector = "";
				newexpr += "[]0->";
			}
			else if ch == "\\" and string_char_at(expr, i+1) == "*" {
				continue;
			}
			else {
				if collector == "" collector = "|"
				collector += ch;
			}
		}
		if collector != "" newexpr += collector + "|";
		return ">" + newexpr + "<";
	}
	#endregion
	
	#region APPLY RULES
	static _apply_rules = function(rls, pos, to) {
		
		var rlen = array_length(rls);
		var i = 0;
		while(i < rlen) {
			
			var r = rls[i];
			var nr = i+1 < rlen ? rls[i+1] : undefined;
			var prev_pos = pos;
			
			switch(r.type) {
				case e_gmre_rule.CHARSET:
					pos = _check_charset(r, pos, to, nr);
					break;
				case e_gmre_rule.STRING:
					pos = _check_string(r, pos, to, nr);
					break;
				case e_gmre_rule.LOOP:
					pos = _check_loop(r, pos, to, nr);
					break;
			}
			
			if pos == -1 return -1;
			if !_check_custom_pos(r, prev_pos, pos) return -1;
			
			i++;
		}
		
		return i == rlen ? pos : -1;
	}
	#endregion
	
	#region CUSTOM POS
	static _check_custom_pos = function(r, from, to) {
		
		var cpr_len = array_length(r.custom_pos_rules);
		for(var cpri = 0; cpri < cpr_len; cpri++) {
			var cpr = r.custom_pos_rules[cpri];
			var cpl = array_length(cpr.custom_pos);
			for(var i = 0; i < cpl; i++) {
				for(var pos = from; pos <= to; pos++) {
					if !_check_custom_pos_get_pos(cpr.custom_pos[i], cpr.custom_pos_eq, pos, from, to, cpr.negated) return false;
				}
			}
		}
		return true;
	}
	
	static _check_custom_pos_get_pos = function(cp, cp_eq, pos, from, to, neg) {
		
		var len = array_length(cp);
		switch(cp[0]) {
			
			case e_gmre_rule.CP_X: // x
			
				if len != 2 return false;
				
				var p = from + cp[1]-1;
				if pos != p break;
				
				if p < 0 or p >= str_len break;
				if !_custom_pos_compare(p, to, cp_eq, neg) return false;
				break;
			
			case e_gmre_rule.CP_NX: // n+-x
				
				if !(len == 1 or len == 3) return false;
				
				if pos != to break;
				var p = to-1;
				
				if len == 3 switch(cp[1]) {
					case "+": p += cp[2]; break;
					case "-": p -= cp[2]; break;
				}
				
				if p < 0 or p >= str_len break;
				if !_custom_pos_compare(p, to, cp_eq, neg) return false;
				break;
			
			case e_gmre_rule.CP_CHARSET: // CHARSET+-x

				if len != 4 return false;
				
				var p = _check_charset(cp[1], pos, to, undefined);
				if p == -1 break;
				p--;
				
				switch(cp[2]) {
					case "+": p = p + cp[3]; break;
					case "-": p = pos - cp[3]; break;
				}
				
				if p < 0 or p >= str_len break;
				if !_custom_pos_compare(p, to, cp_eq, neg) return false;
				break;
			
			case e_gmre_rule.CP_STRING: // STRING+-x
				
				if len != 4 return false;
				
				var p = _check_string(cp[1], pos, to, undefined, false);
				if p == -1 break;
				p--;
				
				switch(cp[2]) {
					case "+": p = p + cp[3]; break;
					case "-": p = pos - cp[3]; break;
				}
				
				if p < 0 or p >= str_len break;
				if !_custom_pos_compare(p, to, cp_eq, neg) return false;
				break;
		}
		
		return true;
	}
	
	static _custom_pos_compare = function(pos, to, cp_eq, neg) {
		
		var eqlen = array_length(cp_eq);
		for(var i = 0; i < eqlen; i++) {
			var cpeq = cp_eq[i];
			switch(cpeq[0]) {
				case e_gmre_rule.CP_CHARSET:
					if _check_charset(cpeq[1], pos, to, undefined) != -1 xor neg return true;
					break;
				case e_gmre_rule.CP_STRING:
					if _check_string(cpeq[1], pos, to, undefined) != -1 xor neg return true;
					break;
			}
		}
		return false;
	}
	#endregion
	
	#region LOOP
	static _check_loop = function(r, pos, to, nr) {
		
		if r.starts_with and pos != 0 return -1;
		if pos >= to return (r.rmin == 0 ? pos : -1);
		
		if array_length(r.rules) == 0 return pos;
		
		var rep = 0;
		while(true) {		
			var p = _apply_rules(r.rules, pos, to);
			if !(p != -1 xor r.negated) break;
			rep++;
			pos = p;
			if pos >= to or rep >= r.rmax break;
		}
		
		return (rep < r.rmin or (r.ends_with and pos < str_len) ? -1 : pos);
	}
	#endregion

	#region CHARSET
	static _check_charset = function(r, pos, to, nr) {
		
		if r.starts_with and pos != 0 return -1;
		if pos >= to return (r.rmin == 0 ? pos : -1);
		
		var rep = 0;
		while(true) {
			if nr != undefined and rep >= r.rmin and r.rmin != r.rmax {
				var nrpos = _apply_rules([nr], pos, to);
				if nrpos != -1 return pos;
			}
			
			var ch = str_arr[pos];
			if !(_ch_in_charset(r, ch) xor r.negated) break;
			rep++;
			pos++;
			if pos >= to or rep >= r.rmax break;
			ch = str_arr[pos];
		}

		return (rep < r.rmin or (r.ends_with and pos < str_len) ? -1 : pos);
	}
	
	static _ch_in_charset = function(r, ch) {
		
		var l = array_length(r.charset);
		if l == 0 return true;
		
		var ch_ascii = ord(ch);
		for(var i = 0; i < l; i++) {
			var chrs = r.charset[i];
			if is_array(chrs) {
				if ch_ascii >= chrs[0] and ch_ascii <= chrs[1] return true;
			}
			else if ch_ascii == chrs return true;
		}
		
		return false;
	}
	#endregion
	
	#region STRING
	static _check_string = function(r, pos, to, nr) {
		
		if r.starts_with and pos != 0 return -1;
		if pos >= to return (r.rmin == 0 ? pos : -1);
		
		var l = array_length(r.str);
		if l == 0 return pos;
		
		var rep = 0;		
		while(true) {
			if nr != undefined and rep >= r.rmin and r.rmin != r.rmax {
				var nrpos = _apply_rules([nr], pos, to);
				if nrpos != -1 return pos;
			}
			
			if !(_str_in_str(r, pos, to) xor r.negated) break;
			rep++;
			pos += l;
			if pos >= to or rep >= r.rmax break;
		}

		return (rep < r.rmin or (r.ends_with and pos < str_len) ? -1 : pos);
	}
	
	static _str_in_str = function(r, pos, to) {
		
		var l = array_length(r.str);
		
		for(var i = 0; i < l; i++) {
			if pos + i >= to return false;
			if str_arr[pos+i] != r.str[i] return false;
		}
		return true;
	}
	#endregion
	
	#region GENERATE RULES
	static _generate_rules = function() {
		
		var loop = undefined;
		var loop_start = 0;
		var last_rule = undefined;
		var next_rule_starts_with = false;
		
		for(var i = 0; i < exp_len; i++) {
			var ch = exp_arr[i];
			var chp = (i != 0 ? exp_arr[i-1] : "");
			
			switch(ch) {
				
				#region START/END WITH
				case ">":
					if i == 1 {
						next_rule_starts_with = true;
					}
					break;
				
				case "<":
					if i == exp_len-1 {
						var rln = array_length(rules);
						if rln > 1 rules[rln-1].ends_with = true;
					}
					break;
				#endregion
				
				#region CHARSET
				case "[":
					if chp == "\\" break;
					
					var r = new _gmre_rule_(e_gmre_rule.CHARSET, chp == "!");
					var closed = false;
					var ri = i+1;
					
					while(ri < exp_len) {
						ch = exp_arr[ri];
						chp = exp_arr[ri-1];
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
					
					if next_rule_starts_with {
						next_rule_starts_with = false;
						r.starts_with = true;
					}
					array_push(loop == undefined ? rules : loop.rules, r);
					last_rule = r;
					i = ri - 1;
					
					break;
				#endregion
				
				#region CUSTOM POS
				case "{":
					if chp == "\\" break;
					if last_rule == undefined return _error("NO RULE TO ATTACH CUSTOM POS RULE TO: " + string(i+1), i+1);
					
					var r = new _gmre_rule_(e_gmre_rule.CUSTOM_POS, chp == "!");
					var closed = false;
					var ri = i+1;
					
					while(ri < exp_len) {
						ch = exp_arr[ri];
						chp = exp_arr[ri-1];
						ri++;
						if ch == "}" and chp != "\\" {
							closed = true;
							break;	
						}
						array_push(r.str, ch);
					}
					if !closed return _error("UNCLOSED CUSTOM POS AT: " + string(i+1), i+1);
					if !r._process_custom_pos() return _error("CUSTOM POS SYNTAX ERROR");
					
					if next_rule_starts_with {
						next_rule_starts_with = false;
						r.starts_with = true;
					}
					array_push(last_rule.custom_pos_rules, r);
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
					
					if next_rule_starts_with {
						next_rule_starts_with = false;
						r.starts_with = true;
					}
					array_push(loop == undefined ? rules : loop.rules, r);
					last_rule = r;
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
					
					var ri = _get_repeats(loop, i+1);
					if floor(ri) != ri return _error("REPEAT SYNTAX ERROR AT: " + string(floor(ri)+1), floor(ri)+1);
					
					array_push(rules, loop);
					last_rule = loop;
					loop = undefined;
					i = ri - 1;
					
					break;
				#endregion
			}
		}
		
		if loop != undefined return _error("UNCLOSED LOOP AT: " + string(loop_start), loop_start);
		
		return true;
	}
	#endregion
	
	#region GET REPEATS
	static _get_repeats = function(r, ri) {
		
		var valid = true;
		var first = true;
		var mn = "";
		var mx = "";
		
		while(ri < exp_len) {
			
			var ch = exp_arr[ri];
			
			if first {
				if _is_number(ch) {
					valid = true;
					mn += ch;
				}
				else if ch == ">" {
					valid = true;
					mn = ch;
					break;
				}
				else if ch == "-" {
					valid = false;
					if mn = "" break;
					first = false;
				}
				else break;
			}
			else {
				if _is_number(ch) {
					valid = true;
					mx += ch;
				}
				else if ch == ">" {
					valid = true;
					mx = ch;
					break;
				}
				else break;
			}
			
			ri++;
		}
		
		if !valid return ri + 0.5;
		
		if mn == ">" {
			r.rmin = 1;
			r.rmax = infinity;
		}
		else if mn != "" {
			r.rmin = real(mn);
			r.rmax = r.rmin;
		}

		if mx == ">" {
			r.rmax = infinity;
		}
		else if mx != "" {
			r.rmax = real(mx);
		}
		
		return ri;
	}
	#endregion
	
	#region OTHER FUNC
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
	#endregion
}
#endregion

#region RULE
function _gmre_rule_(t, n) constructor {
	
	type = t
	negated = n;
	rmin = 1;
	rmax = 1;
	rules = [];
	charset = [];
	str = [];
	custom_pos_rules = [];
	custom_pos = [];
	custom_pos_eq = [];
	
	starts_with = false;
	ends_with = false;
	
	static _process_string = function() {
		
		var s = _unescape(_arr2str(str));
		var l = string_length(s);
		str = array_create(l);
		for(var i = 0; i < l; i++)
			str[i] = string_char_at(s, i+1);
	}
	
	static _process_custom_pos = function() {
		
		_process_string();
		
		var snum = "";
		var a = [-1];
		var eq = false;
		
		var len = array_length(str);
		for(var i = 0; i < len; i++) {
			var ch = str[i];
			var chp = (i != 0 ? str[i-1] : "");
			
			if _is_number(ch) {
				if a[0] == -1 a[0] = e_gmre_rule.CP_X;
				snum += ch;
			}
			else switch(ch) {
				case "n":
					if a[0] == -1 a[0] = e_gmre_rule.CP_NX;
					break;
				
				case "+":
				case "-":
					if a[0] == e_gmre_rule.CP_X break;
					if snum != "" array_push(a, real(snum));
					array_push(a, ch);
					snum = "";
					break;
				
				case ",":
					if snum != "" array_push(a, real(snum));
					array_push(!eq ? custom_pos : custom_pos_eq, a);
					a = [-1];
					snum = "";
					break;
					
				case "=":
					if snum != "" array_push(a, real(snum));
					array_push(custom_pos, a);
					eq = true;
					a = [-1];
					snum = "";
					break;
				
				case "[":
					if chp == "\\" break;
					
					var r = new _gmre_rule_(e_gmre_rule.CHARSET, chp == "!");
					var closed = false;
					var ri = i+1;
					
					while(ri < len) {
						ch = str[ri];
						chp = str[ri-1];
						ri++;
						if ch == "]" and chp != "\\" {
							closed = true;
							break;	
						}	
						array_push(r.str, ch);
					}					
					if !closed break;
					
					ri = _get_repeats(r, ri, len);
					if floor(ri) != ri break;
					
					r._process_charset();
					
					if a[0] == -1 a[0] = e_gmre_rule.CP_CHARSET;
					array_push(a, r);
					snum = "";
					
					i = ri - 1;
					break;
				
				case "|":
					if chp == "\\" break;
					
					var r = new _gmre_rule_(e_gmre_rule.STRING, chp == "!");
					var closed = false;
					var ri = i+1;
					
					while(ri < len) {
						ch = str[ri];
						chp = str[ri-1];
						ri++;
						if ch == "|" and chp != "\\" {
							closed = true;
							break;	
						}
						array_push(r.str, ch);
					}
					if !closed break;
					
					ri = _get_repeats(r, ri, len);
					if floor(ri) != ri break;
					
					r._process_string();
					
					if a[0] == -1 a[0] = e_gmre_rule.CP_STRING;
					array_push(a, r);
					snum = "";
					
					i = ri - 1;
					break;
			}
		}
		
		if a[0] != -1 array_push(custom_pos_eq, a);
		
		return true;
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
	
	static _get_repeats = function(r, ri, exp_len) {
		
		var valid = true;
		var first = true;
		var mn = "";
		var mx = "";
		var from = ri;
		
		while(ri < exp_len) {
			
			var ch = str[ri];
			
			if first {
				if _is_number(ch) {
					valid = true;
					mn += ch;
				}
				else if ch == ">" {
					valid = true;
					mn = ch;
					break;
				}
				else if ch == "-" {
					if ri == from break;
					valid = false;
					if mn = "" break;
					first = false;
				}
				else break;
			}
			else {
				if _is_number(ch) {
					valid = true;
					mx += ch;
				}
				else if ch == ">" {
					valid = true;
					mx = ch;
					break;
				}
				else break;
			}
			
			ri++;
		}
		
		if !valid return ri + 0.5;
		
		if mn == ">" {
			r.rmin = 1;
			r.rmax = infinity;
		}
		else if mn != "" {
			r.rmin = real(mn);
			r.rmax = r.rmin;
		}

		if mx == ">" {
			r.rmax = infinity;
		}
		else if mx != "" {
			r.rmax = real(mx);
		}
		
		return ri;
	}
}
#endregion
