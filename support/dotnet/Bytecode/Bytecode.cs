using System.IO;
using System.Collections.Generic;
using P5Handle = org.mbarbon.p.values.P5Handle;

namespace org.mbarbon.p.runtime
{
    public partial class Serializer
    {
        public static CompilationUnit ReadCompilationUnit(Runtime runtime,
                                                          string file_name)
        {
            CompilationUnit cu;

            using (var fs = File.Open(file_name, FileMode.Open))
            {
                BinaryReader reader = new BinaryReader(fs);
                files = new List<string>();

                int count = reader.ReadInt32();
                int has_data = reader.ReadInt32();
                cu = new CompilationUnit(file_name, count);

                for (int i = 0; i < count; ++i)
                {
                    cu.Subroutines[i] = ReadSubroutine(reader);
                }

                if (has_data != 0)
                {
                    var name = ReadString(reader);
                    var value = ReadString(reader);
                    var glob = runtime.SymbolTable.GetGlob(runtime, name + "::DATA", true);
                    var input = new System.IO.StringReader(value);

                    glob.Handle = new P5Handle(runtime, input, null);
                }
            }
            files = null;

            return cu;
        }

        public static Subroutine ReadSubroutine(BinaryReader reader)
        {
            var name = ReadString(reader);
            int type = reader.ReadByte();
            int outer_sub = reader.ReadInt32();
            int lex_count = reader.ReadInt32();
            int scope_count = reader.ReadInt32();
            int state_count = reader.ReadInt32();
            int bb_count = reader.ReadInt32();
            string regex = null;

            if (type == (int)Subroutine.CodeType.REGEX)
                regex = ReadString(reader);

            var lexicals = new LexicalInfo[lex_count];
            for (int i = 0; i < lex_count; ++i)
                lexicals[i] = ReadLexical(reader);

            var sub = new Subroutine(bb_count);

            sub.Lexicals = lexicals;
            if (name.Length != 0)
                sub.Name = name;
            sub.Outer = outer_sub;
            sub.Type = type;
            sub.OriginalRegex = regex;

            sub.Scopes = new Scope[scope_count];
            for (int i = 0; i < scope_count; ++i)
                sub.Scopes[i] = ReadScope(reader, sub);

            sub.LexicalStates = new LexicalState[state_count];
            for (int i = 0; i < state_count; ++i)
                sub.LexicalStates[i] = ReadLexicalState(reader);

            for (int i = 0; i < bb_count; ++i)
            {
                sub.BasicBlocks[i] = ReadBasicBlock(reader, sub);
            }

            return sub;
        }

        public static LexicalInfo ReadLexical(BinaryReader reader)
        {
            var info = new LexicalInfo();

            info.Level = reader.ReadInt32();
            info.Index = reader.ReadInt32();
            info.OuterIndex = reader.ReadInt32();
            info.Name = ReadString(reader);
            info.Slot = (Opcode.Sigil)reader.ReadByte();
            info.InPad = reader.ReadByte() != 0;
            info.FromMain = reader.ReadByte() != 0;

            return info;
        }

        public static LexicalState ReadLexicalState(BinaryReader reader)
        {
            var state = new LexicalState();

            state.Scope = reader.ReadInt32();
            state.Hints = reader.ReadInt32();
            state.Package = ReadString(reader);
            state.Warnings = ReadString(reader);

            return state;
        }

        public static Scope ReadScope(BinaryReader reader, Subroutine sub)
        {
            var scope = new Scope();

            scope.Outer = reader.ReadInt32();
            scope.Id = reader.ReadInt32();
            scope.Flags = reader.ReadInt32();
            scope.Context = reader.ReadInt32();
            ReadPos(reader, out scope.Start);
            ReadPos(reader, out scope.End);
            scope.LexicalState = reader.ReadInt32();
            scope.Exception = reader.ReadInt32();

            int leave_count = reader.ReadInt32();

            scope.Opcodes = new Opcode[leave_count][];

            for (int i = 0; i < leave_count; ++i)
            {
                int op_count = reader.ReadInt32();
                scope.Opcodes[i] = new Opcode[op_count];

                for (int j = 0; j < op_count; ++j)
                    scope.Opcodes[i][j] = ReadOpcode(reader, sub);
            }

            return scope;
        }

        public static BasicBlock ReadBasicBlock(BinaryReader reader,
                                                Subroutine sub)
        {
            int state = reader.ReadInt32();
            int scope = reader.ReadInt32();
            int count = reader.ReadInt32();
            var bb = new BasicBlock(count);

            bb.LexicalState = state;
            bb.Scope = scope;

            for (int i = 0; i < count; ++i)
            {
                bb.Opcodes[i] = ReadOpcode(reader, sub);
            }

            return bb;
        }

        // ReadOpcode() is autogenerated; see inc/Opcodes.pm

        public static string ReadString(BinaryReader reader)
        {
            int size = reader.ReadInt32();
            if (size == 0)
                return "";

            byte[] bytes = reader.ReadBytes(size);

            return System.Text.Encoding.UTF8.GetString(bytes);
        }

        public static void ReadPos(BinaryReader reader, out Position pos)
        {
            ReadPos(reader, out pos.File, out pos.Line);
        }

        public static void ReadPos(BinaryReader reader,
                                   out string file, out int line)
        {
            var idx = reader.ReadInt16();

            if (idx == -2)
            {
                file = null;
                line = 0;
            }
            else if (idx == -1)
            {
                file = ReadString(reader);
                line = reader.ReadInt32();
                files.Add(file);
            }
            else
            {
                file = files[idx];
                line = reader.ReadInt32();
            }
        }

        private static List<string> files;
    }

    // class Opcode is partially autogenerated; see inc/OpcodesDotNet.pm
    public partial class Opcode
    {
        public enum ContextValues
        {
            CALLER     = 1,
            VOID       = 2,
            SCALAR     = 4,
            LIST       = 8,
            LVALUE     = 16,
            VIVIFY     = 32,
            NOCREATE   = 64,
        }

        public const int RX_CASE_INSENSITIVE = 4;
        public const int RX_ONCE             = 16;
        public const int RX_GLOBAL           = 32;
        public const int RX_KEEP             = 64;

        public enum Sigil
        {
            SCALAR    = 1,
            ARRAY     = 2,
            HASH      = 3,
            SUB       = 4,
            GLOB      = 5,
            HANDLE    = 7,
            ITERATOR  = 9,
            STASH     = 10,
        }

        public OpNumber Number;
        public Position Position;
        public int Context;
        public Opcode[] Childs;
    }

    public struct Position
    {
        public string File;
        public int Line;
    }

    // TODO autogenerate all opcode subclasses
    public class Global : Opcode
    {
        public string Name;
        public Opcode.Sigil Slot;
    }

    public class LocalGlobSlot : Opcode
    {
        public string Name;
        public Opcode.Sigil Slot;
        public int Index;
    }

    public class GlobSlot : Opcode
    {
        public Opcode.Sigil Slot;
    }

    public class ConstantInt : Opcode
    {
        public int Value;
    }

    public class ConstantString : Opcode
    {
        public string Value;
    }

    public class ConstantSub : Opcode
    {
        public int Value;
    }

    public class ConstantFloat : Opcode
    {
        public double Value;
    }

    public class GetSet : Opcode
    {
        public int Index;
    }

    public class Jump : Opcode
    {
        public int To;
    }

    public class LexState : Opcode
    {
        public int Index;
    }

    public class Temporary : Opcode
    {
        public int Index;
        public Opcode.Sigil Slot;
    }

    public class ElementAccess : Opcode
    {
        public int Create;
    }

    public class Lexical : Opcode
    {
        public LexicalInfo LexicalInfo;

        public int LexicalIndex
        {
            get { return LexicalInfo.Index; }
        }

        public Opcode.Sigil Slot
        {
            get { return LexicalInfo.Slot; }
        }
    }

    public class CallMethod : Opcode
    {
        public string Method;
    }

    public class RegexExact : Opcode
    {
        public string String;
        public int Length;
    }

    public class RegexClass : Opcode
    {
        public string Elements;
    }

    public class RegexAccept : Opcode
    {
        public int Groups;
    }

    public class RegexStartGroup : Opcode
    {
        public int To;
    }

    public class RegexTry : Opcode
    {
        public int To;
    }

    public class RegexQuantifier : Opcode
    {
        public int Min, Max;
        public byte Greedy;
        public int Group;
        public int To;
        public int SubgroupsStart, SubgroupsEnd;
    }

    public class RegexCapture : Opcode
    {
        public int Group;
    }

    public class RegexState : Opcode
    {
        public int Index;
    }

    public class RegexMatch : Opcode
    {
        public int Index;
        public int Flags;
        public int To; // for replace only
    }

    public class Scope
    {
        public const int SCOPE_SUB       = 1;
        public const int SCOPE_EVAL      = 2;
        public const int SCOPE_MAIN      = 4;
        public const int SCOPE_LEX_STATE = 8;
        public const int SCOPE_REGEX     = 16;
        public const int SCOPE_VALUE     = 32;

        public int Outer;
        public int Id;
        public int Flags;
        public int Context;
        public Opcode[][] Opcodes;
        public Position Start;
        public Position End;
        public int LexicalState;
        public int Exception;
    }

    public class LexicalState
    {
        public int Scope;
        public int Hints;
        public string Package;
        public string Warnings;
    }

    public class BasicBlock
    {
        public BasicBlock(int opCount)
        {
            Opcodes = new Opcode[opCount];
        }

        public int Index;
        public int LexicalState;
        public int Scope;
        public Opcode[] Opcodes;
    }

    public class Subroutine
    {
        public enum CodeType
        {
            MAIN    = 1,
            SUB     = 2,
            REGEX   = 3,
            EVAL    = 4,
        }

        public Subroutine(int blockCount)
        {
            BasicBlocks = new BasicBlock[blockCount];
        }

        public bool IsMain
        {
            get { return Type == (int)CodeType.MAIN; }
        }

        public bool IsRegex
        {
            get { return Type == (int)CodeType.REGEX; }
        }

        public int Type;
        public int Outer;
        public string Name;
        public BasicBlock[] BasicBlocks;
        public LexicalInfo[] Lexicals;
        public Scope[] Scopes;
        public LexicalState[] LexicalStates;
        public string OriginalRegex;
    }

    public class CompilationUnit
    {
        public CompilationUnit(string file_name, int subCount)
        {
            Subroutines = new Subroutine[subCount];
            FileName = file_name;
        }

        public string FileName;
        public Subroutine[] Subroutines;
    }

    public class LexicalInfo
    {
        public LexicalInfo()
            : this(null, 0, -1, -1, -1, false, false)
        { }

        public LexicalInfo(string name, Opcode.Sigil slot,
                           int level, int index, int outer,
                           bool in_pad, bool from_main)
        {
            Level = level;
            Index = index;
            OuterIndex = outer;
            Slot = slot;
            InPad = in_pad;
            FromMain = from_main;
            Name = name;
        }

        public int Level, Index, OuterIndex;
        public Opcode.Sigil Slot;
        public bool InPad, FromMain;
        public string Name;
    }
}
