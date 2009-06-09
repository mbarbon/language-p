using Runtime = org.mbarbon.p.runtime.Runtime;

namespace org.mbarbon.p.values
{
    public class Reference : IScalarBody
    {
        public Reference(Runtime runtime, IReferrable val)
        {
            referred = val;
        }

        public virtual IScalarBody CloneBody(Runtime runtime)
        {
            return new Reference(runtime, referred);
        }

        public virtual string AsString(Runtime runtime)
        {
            return "SOMETHING";
        }

        public virtual int AsInteger(Runtime runtime)
        {
            return -1;
        }

        public virtual double AsFloat(Runtime runtime)
        {
            return AsInteger(runtime);
        }

        public virtual bool AsBoolean(Runtime runtime)
        {
            return true;
        }

        public virtual Code DereferenceSubroutine(Runtime runtime)
        {
            Code val = referred as Code;

            if (val != null)
                return val;
            else
                throw new System.Exception("Not a CODE reference");
        }

        private IReferrable referred;
    }
}
