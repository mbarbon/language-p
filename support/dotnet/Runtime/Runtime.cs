using org.mbarbon.p.values;
using System.Collections.Generic;

namespace org.mbarbon.p.runtime
{
    public struct SavedLexState
    {
        public string Package;
        public int Hints;
    }

    public struct SavedValue
    {
        public IP5Any container;
        public IP5Any value;
        public int int_key;
        public string str_key;
    }

    public class StackFrame
    {
        public StackFrame(string pack, string file, int l, P5Code code,
                          Opcode.ContextValues cxt, bool eval)
        {
            Package = pack;
            File = file;
            Line = l;
            Code = code;
            Context = cxt;
            IsEval = eval;
        }

        public string Package;
        public string File;
        public int Line;
        public P5Code Code;
        public Opcode.ContextValues Context;
        public bool IsEval;
    }

    public class Runtime
    {
        public static System.Guid PerlGuid3 =
            new System.Guid("3FC48569-0551-4114-BF17-735ED691526B");

        public Runtime()
        {
            SymbolTable = new P5MainSymbolTable(this, "main");
            CallStack = new Stack<StackFrame>();

            // set up INC
            SymbolTable.GetArray(this, "INC", true).Assign(
                this, new P5Scalar(this, "."));
        }

        public void SetException(P5Exception e)
        {
            P5Scalar s = e.Reference;

            if (s == null)
                s = new P5Scalar(this, e.Message);

            SymbolTable.GetStashScalar(this, "@", true).Assign(this, s);
        }

        public IP5Any CallerNoArg(Opcode.ContextValues cxt)
        {
            return Caller(false, 0, cxt);
        }

        public IP5Any CallerWithArg(IP5Any level, Opcode.ContextValues cxt)
        {
            return Caller(false, level.AsScalar(this).AsInteger(this), cxt);
        }

        private IP5Any Caller(bool noarg, int level, Opcode.ContextValues cxt)
        {
            StackFrame frame = null;

            if (level == 0)
                frame = CallStack.Peek();
            else if (level > 0)
            {
                foreach (var f in CallStack)
                {
                    if (level == 0)
                    {
                        frame = f;
                        break;
                    }

                    --level;
                }
            }

            if (frame == null)
                return new P5List(this);

            if (cxt == Opcode.ContextValues.SCALAR)
                return new P5Scalar(this, frame.Package);
            else if (noarg)
                return new P5List(
                    this,
                    new P5Scalar(this, frame.Package),
                    new P5Scalar(this, frame.File),
                    new P5Scalar(this, frame.Line));
            else
            {
                var callcxt =
                    frame.Context == Opcode.ContextValues.VOID   ? new P5Scalar(this) :
                    frame.Context == Opcode.ContextValues.SCALAR ? new P5Scalar(this, "") :
                                                                   new P5Scalar(this, 1);
                return new P5List(
                    this,
                    new P5Scalar(this, frame.Package),
                    new P5Scalar(this, frame.File),
                    new P5Scalar(this, frame.Line),
                    new P5Scalar(this), // sub
                    new P5Scalar(this), // hasargs
                    callcxt, // context
                    new P5Scalar(this), // evaltext
                    new P5Scalar(this), // is_require
                    new P5Scalar(this), // hints
                    new P5Scalar(this)); // warnings
            }
        }

        public Opcode.ContextValues CurrentContext()
        {
            return CallStack.Peek().Context;
        }

        public P5MainSymbolTable SymbolTable;
        public Stack<StackFrame> CallStack;
        public string File, Package;
        public int Line, Hints;
        public RxResult LastMatch;
    }
}
