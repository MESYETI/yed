import std.file, std.conv, std.array, std.stdio, std.string, std.algorithm;

string[] Parse(string str) {
	string[] res;
	string   reading;

	for (size_t i = 0; i < str.length; ++ i) {
		switch (str[i]) {
			case '#': {
				if (reading == "") break;

				res    ~= reading;
				reading  = "";
				break;
			}
			case '\\': {
				++ i;
				if (i == str.length) throw new Exception("Escape has no character");
				switch (str[i]) {
					case '#':  reading ~= '#';  break;
					case '\\': reading ~= '\\'; break;
					default:  throw new Exception("Invalid escape character");
				}
				break;
			}
			default: reading ~= str[i];
		}
	}

	if (reading != "") res ~= reading;
	return res;
}

class Buffer {
	string[] buf;
	long     line = -1;
	string   path;

	static Buffer FromFile(string path) {
		auto buf = new Buffer();
		buf.buf  = readText(path).replace("\r\n", "\n").split('\n');

		if (buf.buf[$ - 1] == "") buf.buf = buf.buf[0 .. $ - 1];

		return buf;
	}

	void Insert(string str) {
		buf = buf[0 .. line] ~ str ~ buf[line .. $];
	}

	void Save() {
		if (path == "") {
			throw new Exception("Nowhere to write file");
		}

		std.file.write(path, buf.join("\n") ~ '\n');
	}

	ref string GetLine(long index) {
		if ((index < 0) && (index >= buf.length)) {
			throw new Exception("Out of bounds read");
		}

		return buf[index];
	}

	ref string GetLine() => GetLine(line);
}

enum ArgType {
	Integer, Other
}

struct Command {
	ArgType[]       requiredArgs;
	void delegate() func;

	bool Verify(ref string[] stack) {
		if (stack.length < requiredArgs.length) return false;

		foreach (i, ref arg ; stack[$ - requiredArgs.length .. $]) {
			final switch (requiredArgs[i]) {
				case ArgType.Integer: if (!arg.isNumeric()) return false; break;
				case ArgType.Other:   break;
			}
		}

		return true;
	}
}

class Editor {
	Buffer[size_t]  buffers = [0: new Buffer()];
	size_t          current;
	string[]        stack;
	Command[string] cmds;

	this() {
		cmds["la"] = Command([], () {
			foreach (i, ref line ; buffers[current].buf) writefln("%d\t%s", i + 1, line);
		});
		cmds["n"] = Command([ArgType.Integer], () {
			buffers[current].line = Pop().to!long() - 1;
			writeln(buffers[current].line + 1);
		});
		cmds["n?"] = Command([], () {
			stack ~= text(buffers[current].line + 1);
		});
		cmds["l"] = Command([ArgType.Integer, ArgType.Integer], () {
			long from, to;
			to   = Pop().to!long() - 1;
			from = Pop().to!long() - 1;

			for (long i = from; i <= to; ++ i) {
				writefln("%d\t%s", i + 1, buffers[current].GetLine(i));
			}
		});
		cmds["o"] = Command([ArgType.Other], () {
			buffers[current] = Buffer.FromFile(Pop());
		});
		cmds["s"] = Command([], () {
			buffers[current].Save();
		});
		cmds["sa"] = Command([ArgType.Other], () {
			buffers[current].path = Pop();
			buffers[current].Save();
		});
		cmds["dup"] = Command([ArgType.Other], () {
			auto val = Pop();
			stack ~= [val, val];
		});
		cmds["r"] = Command([ArgType.Other, ArgType.Other], () {
			auto to   = Pop();
			auto from = Pop();
			buffers[current].GetLine() = buffers[current].GetLine().replace(from, to);
		});
		cmds["end?"] = Command([], () {
			stack ~= buffers[current].buf.length.text();
		});
		cmds["p"] = Command([], () {
			writefln("%d\t%s", buffers[current].line + 1, buffers[current].GetLine());
		});
		cmds["b"] = Command([ArgType.Integer], () {
			current = Pop().to!long();
			if (current !in buffers) buffers[current] = new Buffer();
		});
		cmds["f"] = Command([ArgType.Other], () {
			auto param = Pop();
			foreach (i, ref line ; buffers[current].buf) {
				if (line.canFind(param)) writefln("%d\t%s", i + 1, line);
			}
		});
	}

	string Pop() {
		if (stack.length == 0) {
			throw new Exception("Stack underflow");
		}

		auto res = stack[$ - 1];
		stack    = stack[0 .. $ - 1];
		return res;
	}

	void RunCommand(string input) {
		if ((input.length > 0) && (input[0] == '#')) {
			string[] cmd;

			try {
				cmd = input[1 .. $].Parse();
			}
			catch (Exception e) {
				stderr.writeln(e.msg);
				return;
			}

			foreach (ref part ; cmd) {
				if (part.startsWith(".") && !part.startsWith("..")) {
					if (part[1 .. $] !in cmds) {
						stderr.writefln("Command '%s' doesn't exist", part[1 .. $]);
						return;
					}
					if (!cmds[part[1 .. $]].Verify(stack)) {
						stderr.writefln("Command has invalid parameters");
						return;
					}

					cmds[part[1 .. $]].func();
				}
				else if (part.startsWith("..")) {
					stack ~= part[1 .. $];
				}
				else {
					stack ~= part;
				}
			}
		}
		else {
			++ buffers[current].line;
			buffers[current].Insert(input.Parse().join(" "));
		}
	}
}

int main(string[] args) {
	writeln("yed 1.0");
	auto editor = new Editor();

	foreach (i, ref arg ; args[1 .. $]) {
		try {
			editor.buffers[i] = Buffer.FromFile(arg);
		}
		catch (Exception e) {
			stderr.writefln("Failed to open '%s': %s", arg, e.msg);
			return 1;
		}
	}

	while (true) {
		write("> ");
		stdout.flush();
		string input = readln()[0 .. $ - 1];

		try {
			editor.RunCommand(input);
		}
		catch (Exception e) {
			stderr.writeln(e.msg);
		}
	}
}
