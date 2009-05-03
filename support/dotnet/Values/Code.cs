using org.mbarbon.p.runtime;
using org.mbarbon.p.values;

namespace org.mbarbon.p.values
{
    public class Code
    {       
        public Code(System.Delegate code)
        {
            SubRef = (Sub)code;
        }

        public IAny Call(Runtime runtime, Opcode.Context context, Array args)
        {
            return SubRef(runtime, context, null, args);
        }
        
        public delegate IAny Sub(Runtime runtime, Opcode.Context context,
                                 ScratchPad pad, Array args);

        private Sub SubRef;
    }
}
