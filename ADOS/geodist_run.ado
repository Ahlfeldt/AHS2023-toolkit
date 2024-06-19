*! version 1.0.0    04june2019    Robert Picard    <robertpicard@gmail.com>
program define geodist_run

	version 9.2
	
	syntax anything(name=example_name id="example name") ///
		using/			///
		,				///
		[requires(string)]	///
		[preserve]
	
	
	local package geodist
	local p1 = substr("`package'", 1,1)
	
	if `"`requires'"' != "" {
		foreach f of local requires {
			cap confirm file `f'
			if _rc {
				dis as err "a dataset used in this example is not in the current directory"
				dis as err `"> {it:{stata `"net get `package', from("http://fmwww.bc.edu/repec/bocode/`p1'")"':click to install `package' example datasets from SSC}}"'
				exit 601
			}
		}
	}
	
	
	quietly {
	
		findfile `"`using'"'

		`preserve'
		
		infix str s 1-244 using `"`r(fn)'"', clear
		
		gen long obs = _n
		
		sum obs if strpos(s, "{* example_start - `example_name'}{...}")
		if r(min) == . {
			dis as err "example `example_name' not found"
			exit 111
		}
		local pos1 = r(min) + 1
		sum obs if strpos(s, "{* example_end}{...}") & obs > `pos1'
		local pos2 = r(min) - 1
	
		if mi(`pos1',`pos2') exit
		
		keep in `pos1'/`pos2'
		
		// remove code hidden in SMCL comments
		replace s = regexr(trim(s), "}{...}", "") if substr(s,1,3) == "{* "
		replace s = substr(s,4,.) if substr(s,1,3) == "{* "
		
	}
	
	tempfile f
	outfile s using "`f'", noquote
	do "`f'"
	
end
