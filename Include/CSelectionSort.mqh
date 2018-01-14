//+------------------------------------------------------------------+
//|                                               CSelectionSort.mqh |
//|                                    Copyright 2017, Erwin Beckers |
//|                                      https://www.erwinbeckers.nl |
//+------------------------------------------------------------------+
#property copyright "Copyright 2017, Erwin Beckers"
#property link      "https://www.erwinbeckers.nl"
#property strict

template<typename T> 
interface ICompare
{
  int Compare(T el1, T el2);
};

template<typename T> 
class CSelectionSort
{
public:
   void Sort(T &array[], int arraySize, ICompare<T>* comparer)
   {
      int minKey;
      for (int j = 0; j < arraySize - 1; j++)
      {
         minKey = j;
         for (int k = j + 1; k < arraySize; k++)
         {
            if ( comparer.Compare(array[k] , array[minKey]) < 0)
            {
               minKey = k;
            }
         }
         
         if (minKey != j)
         {
            T tmp           = array[minKey];
            array[minKey]   = array[j];
            array[j]        = tmp;
         }
      }
   }
};
