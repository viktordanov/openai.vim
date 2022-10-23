if exists('g:autoloaded_openai')
	finish
endif
let g:autoloaded_openai = 1

" OpenAIComplete takes in either the visual selection of text or the line the
" cursor is currently on (if there is no visual selection) and appends the
" completed text from the OpenAI API.
function! openai#Complete()
	" Get the position of the cursor, if it is the start of the file we want
	" a different behavior than if it is elsewhere.
	let end_line = getpos("'>'")[1]
	let text = GetVisualSelection()
	if len(text) < 1
		" Get the current line instead.
		let end_line = getpos(".")[1]
		let lines = getline(0, end_line)
		let clean_lines = []
		for line in lines
			let clean_lines += [substitute(trim(line), '\n', '', 'g')]
		endfor
		let text = join(clean_lines, "\\n")
	endif
	if len(text) < 1
		echohl Error
		echom "Must have text selected or have cursor on a line of text."
		echohl None
		return
	endif

	" Curl the OpenAI API and pipe the result to jq.
	let openai_api_key = $OPENAI_API_KEY
	let text = trim(text)
	let text = substitute(text, '"', '\"', 'g')
	let text = substitute(text, "'", "\'", 'g')
	let command = "curl -s -H 'Authorization: Bearer " . openai_api_key . "' -H 'Content-Type: application/json' -d '{\"prompt\": \"" . text . "\", \"max_tokens\": 64, \"temperature\": 0.5, \"top_p\": 1, \"frequency_penalty\": 0, \"presence_penalty\": 0, \"stop\": [\"\\n\", \"\\n\\n\"], \"model\": \"text-davinci-002\"}' https://api.openai.com/v1/completions | jq -r '.choices[0].text'"

	let curl_output = trim(system(command))
	system("notify-send 'OpenAI Complete' '" . curl_output . "'")
	" Append the text back to the selection or current line.
	call append(end_line, split(curl_output, "\n"))
endfunction

" GetVisualSelection returns the text in a visual selection.
function! GetVisualSelection()
	let [line_start, column_start] = getpos("'<")[1:2]
	let [line_end, column_end] = getpos("'>")[1:2]
	let lines = getline(line_start, line_end)
	if len(lines) == 0
		return ''
	endif
	let lines[-1] = lines[-1][: column_end - (&selection == 'inclusive' ? 1 : 2)]
	let lines[0] = lines[0][column_start - 1:]
	let clean_lines = []
	for line in lines
		let clean_lines += [substitute(trim(line), '\n', '', 'g')]
	endfor
	return join(clean_lines, "\\n")
endfunction
