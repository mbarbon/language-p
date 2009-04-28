using org.mbarbon.p.runtime;

namespace org.mbarbon.p.values
{
    public class Code
    {       
        public Code(System.Delegate code)
        {
            Delegate = code;
        }

        public IAny Call(Runtime runtime, Opcode.Context context, Array args)
        {
            var ret = Delegate.DynamicInvoke(runtime, context, null, args);

            return (IAny)ret;
        }
        
        private System.Delegate Delegate;
    }
}
