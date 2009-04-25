using org.mbarbon.p.runtime;

namespace org.mbarbon.p.values
{
    public class Code
    {       
        public Code(System.Delegate code)
        {
            Delegate = code;
        }

        public void Call(Runtime runtime, Array args)
        {
            Delegate.DynamicInvoke(runtime, args);
        }
        
        private System.Delegate Delegate;
    }
}
