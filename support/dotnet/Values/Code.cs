using org.mbarbon.p.runtime;
using org.mbarbon.p.values;

namespace org.mbarbon.p.values
{
    public class P5Code : IP5Referrable
    {
        public P5Code(string _name)
        {
            subref = new Sub(UndefinedSub);
            scratchpad = null;
            is_main = false;
            name = _name;
        }

        public bool IsDefined(Runtime runtime)
        {
            return subref != (Sub)UndefinedSub;
        }

        public P5Code(string _name, System.Delegate code, bool main)
        {
            subref = (Sub)code;
            scratchpad = null;
            is_main = main;
            name = _name;
        }

        public void Assign(Runtime runtime, P5Code other)
        {
            subref = other.subref;
            scratchpad = other.scratchpad;
        }

        private IP5Any UndefinedSub(Runtime runtime,
                                    Opcode.ContextValues context,
                                    P5ScratchPad pad, P5Array args)
        {
            var msg = string.Format("Undefined subroutine &{0:S} called",
                                    Name);

            throw new P5Exception(runtime, msg);
        }

        public virtual IP5Any Call(Runtime runtime, Opcode.ContextValues context,
                                   P5Array args)
        {
            // TODO emit this in the subroutine prologue/epilogue code,
            //      as is done for eval BLOCK
            P5ScratchPad pad = scratchpad;
            if (scratchpad != null && !is_main)
                pad = scratchpad.NewScope(runtime);
            int size = runtime.CallStack.Count;

            try
            {
                runtime.CallStack.Push(new StackFrame(runtime.Package,
                                                      runtime.File,
                                                      runtime.Line, this,
                                                      context, false));
                return subref(runtime, context, pad, args);
            }
            finally
            {
                StackFrame frame = null;
                while (runtime.CallStack.Count > size)
                    frame = runtime.CallStack.Pop();

                if (frame != null)
                {
                    runtime.Package = frame.Package;
                    runtime.File = frame.File;
                    runtime.Line = frame.Line;
                }
            }
        }

        // P5MainCode and P5BeginCode subclasses?
        public virtual IP5Any CallMain(Runtime runtime)
        {
            return subref(runtime, Opcode.ContextValues.VOID, scratchpad, null);
        }

        public void NewScope(Runtime runtime)
        {
            if (scratchpad != null)
                scratchpad = scratchpad.NewScope(runtime);
        }

        public P5Scalar MakeClosure(Runtime runtime, P5ScratchPad outer)
        {
            P5Code closure = new P5Code(name, subref, is_main);
            closure.scratchpad = scratchpad.CloseOver(runtime, outer);

            return new P5Scalar(runtime, closure);
        }

        public virtual void Bless(Runtime runtime, P5SymbolTable stash)
        {
            blessed = stash;
        }

        public virtual bool IsBlessed(Runtime runtime)
        {
            return blessed != null;
        }

        public virtual P5SymbolTable Blessed(Runtime runtime)
        {
            return blessed;
        }

        public P5ScratchPad ScratchPad
        {
            get { return scratchpad; }
            set { scratchpad = value; }
        }

        public string Name
        {
            get { return name.IndexOf("::") == -1 ? "main::" + name : name; }
        }

        protected Sub Subref { get { return subref; } }

        public delegate IP5Any Sub(Runtime runtime,
                                   Opcode.ContextValues context,
                                   P5ScratchPad pad, P5Array args);

        private P5SymbolTable blessed;
        private Sub subref;
        private P5ScratchPad scratchpad;
        private bool is_main;
        private string name;
    }

    public class P5NativeCode : P5Code
    {
        public P5NativeCode(string name, System.Delegate code) :
            base(name, code, false)
        {
        }

        public override IP5Any Call(Runtime runtime, Opcode.ContextValues context,
                                    P5Array args)
        {
            int size = runtime.CallStack.Count;

            try
            {
                runtime.CallStack.Push(new StackFrame(runtime.Package,
                                                      runtime.File,
                                                      runtime.Line, this,
                                                      context, false));
                return Subref(runtime, context, ScratchPad, args);
            }
            finally
            {
                while (runtime.CallStack.Count > size)
                    runtime.CallStack.Pop();
            }
        }
    }
}
