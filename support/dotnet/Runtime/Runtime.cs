using org.mbarbon.p.values;

namespace org.mbarbon.p.runtime
{
    public class Runtime
    {       
        public Runtime()
        {
            SymbolTable = new SymbolTable(this);
        }

        public SymbolTable SymbolTable;
    }
}
