using Runtime = org.mbarbon.p.runtime.Runtime;

namespace org.mbarbon.p.values
{   
    public interface IAny
    {
        IAny AsScalar(Runtime runtime);
        string AsString(Runtime runtime);
        int AsInteger(Runtime runtime);
        double AsFloat(Runtime runtime);
    }
}
