using Runtime = org.mbarbon.p.runtime.Runtime;

namespace org.mbarbon.p.values
{
    public class P5Reference : IP5ScalarBody
    {
        public P5Reference(Runtime runtime, IP5Referrable val)
        {
            referred = val;
        }

        public virtual IP5ScalarBody CloneBody(Runtime runtime)
        {
            return new P5Reference(runtime, referred);
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

        public virtual P5Code DereferenceSubroutine(Runtime runtime)
        {
            P5Code val = referred as P5Code;

            if (val != null)
                return val;
            else
                throw new System.Exception("Not a CODE reference");
        }

        internal IP5Referrable Referred
        {
            get
            {
                return referred;
            }
        }

        private IP5Referrable referred;
    }
}
