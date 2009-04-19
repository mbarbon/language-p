using Runtime = org.mbarbon.p.runtime.Runtime;

namespace org.mbarbon.p.values
{   
    public interface IAny
    {
        Scalar AsScalar(Runtime runtime);
        string AsString(Runtime runtime);
        int AsInteger(Runtime runtime);
        double AsFloat(Runtime runtime);
    }
}
