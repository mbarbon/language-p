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
            P5ScratchPad pad = scratchpad;
            if (scratchpad != null && !is_main)
                pad = scratchpad.NewScope(runtime);

            return subref(runtime, context, pad, args);
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

        public P5ScratchPad ScratchPad
        {
            get { return scratchpad; }
            set { scratchpad = value; }
        }

        public delegate IP5Any Sub(Runtime runtime,
                                   Opcode.ContextValues context,
                                   P5ScratchPad pad, P5Array args);

        private Sub subref;
        private P5ScratchPad scratchpad;
        private bool is_main;
    }
}
