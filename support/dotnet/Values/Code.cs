using org.mbarbon.p.runtime;
using org.mbarbon.p.values;

namespace org.mbarbon.p.values
{
    public class P5Code : IP5Referrable
    {
        public P5Code(System.Delegate code, bool main)
        {
            subref = (Sub)code;
            scratchpad = null;
            is_main = main;
        }

        public IP5Any Call(Runtime runtime, Opcode.ContextValues context,
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
                while (runtime.CallStack.Count > size)
                    runtime.CallStack.Pop();
            }
        }

        public void NewScope(Runtime runtime)
        {
            if (scratchpad != null)
                scratchpad = scratchpad.NewScope(runtime);
        }

        public P5Scalar MakeClosure(Runtime runtime, P5ScratchPad outer)
        {
            P5Code closure = new P5Code(subref, is_main);
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

        public delegate IP5Any Sub(Runtime runtime,
                                   Opcode.ContextValues context,
                                   P5ScratchPad pad, P5Array args);

        private P5SymbolTable blessed;
        private Sub subref;
        private P5ScratchPad scratchpad;
        private bool is_main;
    }
}
