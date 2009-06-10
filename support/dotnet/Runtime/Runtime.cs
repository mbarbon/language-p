using org.mbarbon.p.values;

namespace org.mbarbon.p.runtime
{
    public class Runtime
    {       
        public Runtime()
        {
            SymbolTable = new P5MainSymbolTable(this);
        }

        public P5MainSymbolTable SymbolTable;
    }
}
