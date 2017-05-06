/**
 * Copyright 2012 by dueni.ch
 *
 * Licensed under the Apache License, Version 2.0 (the "License");
 * you may not use this file except in compliance with the License.
 * You may obtain a copy of the License at
 *
 *     http://www.apache.org/licenses/LICENSE-2.0
 *
 * Unless required by applicable law or agreed to in writing, software
 * distributed under the License is distributed on an "AS IS" BASIS,
 * WITHOUT WARRANTIES OR CONDITIONS OF ANY KIND, either express or implied.
 * See the License for the specific language governing permissions and
 * limitations under the License.
 */

package ch.dueni.util.collections;

import java.util.Collection;
import java.util.Collections;
import java.util.Iterator;
import java.util.List;
import java.util.ListIterator;

/**
 * <code>CreateOnWriteList</code> is intended to be used for most likely empty lists within objects
 * that are intended to keep in session and therefore may occupy memory for long time.&nbsp;
 * <code>CreateOnWriteList</code> in best usage case will use 0 bytes of memory and still provides a
 * fully operable List implementation using a call-back method to create the real list before first
 * {@link List#add(Object)} operation is executed.
 * <p>
 * Memory analysis for different types of lists show:
 * </p>
 * 
 * <pre>
 * Nr Test case                                           retained   shallow
 * == ==================================================  =========  =======
 *  1 ArrayList (default size)                                 80       24
 *  2 ArrayList (size 0)                                       40       24
 *  3 LinkedList (empty)                                       48       24
 *  4 CreatOnWriteList (empty, assigned to var)                32       16
 *  5 CreatOnWriteList (return new from getList() method)       0        0
 * </pre>
 * 
 * <h5>Example code for above test nr 4</h5>
 * 
 * <pre>
 * public class MyOwner {
 * 	private List&lt;String&gt; list;
 * 
 * 	public MyOwner() {
 * 		list = new CreateOnWriteList&lt;String&gt;() {
 * 			&#064;Override
 * 			public List&lt;String&gt; newList() {
 * 				list = new ArrayList&lt;String&gt;(1); // init with minimal size to use less memory
 * 				return list;
 * 			}
 * 		};
 * 	}
 * 
 * 	public List&lt;String&gt; getList() {
 * 		return list;
 * 	}
 * }
 * </pre>
 * 
 * <h5>Example code for above test nr 5</h5>
 * 
 * <pre>
 * public class MyOwner {
 * 	private List&lt;String&gt; list;
 * 
 * 	public MyOwner() {
 * 	}
 * 
 * 	public List&lt;String&gt; getList() {
 * 		if (list == null) {
 * 			return new CreateOnWriteList&lt;String&gt;() {
 * 				&#064;Override
 * 				public List&lt;String&gt; newList() {
 * 					list = new ArrayList&lt;String&gt;(1); // init with minimal size to use less memory
 * 					return list;
 * 				}
 * 			};
 * 		}
 * 		return list;
 * 	}
 * }
 * </pre>
 * 
 * <h5>Which variant to use?</h5>
 * <p>
 * It is recommended to return new CreateOnWriteList within the get-method as shown in
 * "example code for test nr 5" unless you have very frequent access to empty lists without adding
 * entries.
 * </p>
 * 
 * @author Hanspeter D&uuml;nnenberger
 */
public abstract class CreateOnWriteList<E> implements List<E> {

	/** local variable for the wrapped list to create as late as possible */
	private List<E> wrapped;

	/**
	 * Return the just created real List after assigning it to the owning object's member variable.
	 * 
	 * <pre>
	 * <code>
	 * public class OwningType {
	 *   private List<String> list;
	 *   
	 *   public List<String> getList() {
	 *     if (list == null) {
	 *       return new CreateOnWriteList<String>() {
	 * 
	 *         &#64;Override
	 *         public List<String> newList() { 
	 *           list = new ArrayList<String>(1);
	 *           return list;
	 *         }
	 *       };
	 *     }
	 *     return list;
	 *   }
	 * } 
	 * </code>
	 * </pre>
	 * 
	 * @return the just created real List after assigning it to the owning object's member variable.
	 */
	public abstract List<E> newList();

	/**
	 * Make sure wrapped is assigned from {@link #newList()} return the wrapped List.
	 * 
	 * @return the real List as returned and kept from the {@link #newList()}.
	 */
	private List<E> getWrapped() {
		if (wrapped == null) {
			wrapped = newList();
		}
		return wrapped;
	}

	/**
	 * Make sure wrapped is assigned from {@link #newList()} and delegate the passed argument to the
	 * wrapped List.
	 * 
	 * @see List#add(Object)
	 */
	@Override
	public boolean add(E e) {
		return getWrapped().add(e);
	}

	/**
	 * Make sure wrapped is assigned from {@link #newList()} and delegate the passed argument to the
	 * wrapped List.
	 * 
	 * @see List#add(int, Object)
	 */
	@Override
	public void add(int index, E element) {
		getWrapped().add(index, element);
	}

	/**
	 * Make sure wrapped is assigned from {@link #newList()} and delegate the passed argument to the
	 * wrapped List.
	 * 
	 * @see List#addAll(Collection)
	 */
	@Override
	public boolean addAll(Collection<? extends E> c) {
		return getWrapped().addAll(c);
	}

	/**
	 * Make sure wrapped is assigned from {@link #newList()} and delegate the passed argument to the
	 * wrapped List.
	 * 
	 * @see List#addAll(int, Collection)
	 */
	@Override
	public boolean addAll(int index, Collection<? extends E> c) {
		return getWrapped().addAll(index, c);
	}

	@Override
	public void clear() {
		if (wrapped != null) {
			wrapped.clear();
		}
	}

	@Override
	public boolean contains(Object o) {
		if (wrapped != null) {
			return wrapped.contains(o);
		}
		return false;
	}

	@Override
	public boolean containsAll(Collection<?> c) {
		if (wrapped != null) {
			return wrapped.containsAll(c);
		}
		return false;
	}

	@Override
	public E get(int index) {
		if (wrapped != null) {
			return wrapped.get(index);
		}
		return null;
	}

	@Override
	public int indexOf(Object o) {
		if (wrapped != null) {
			return wrapped.indexOf(o);
		}
		return -1;
	}

	@Override
	public boolean isEmpty() {
		if (wrapped != null) {
			return wrapped.isEmpty();
		}
		return true;
	}

	@Override
	@SuppressWarnings("unchecked")
	public Iterator<E> iterator() {
		if (wrapped != null) {
			return wrapped.iterator();
		}
		return Collections.EMPTY_LIST.iterator();
	}

	@Override
	public int lastIndexOf(Object o) {
		if (wrapped != null) {
			return wrapped.lastIndexOf(o);
		}
		return -1;
	}

	@Override
	@SuppressWarnings("unchecked")
	public ListIterator<E> listIterator() {
		if (wrapped != null) {
			return wrapped.listIterator();
		}
		return Collections.EMPTY_LIST.listIterator();
	}

	@Override
	@SuppressWarnings("unchecked")
	public ListIterator<E> listIterator(int index) {
		if (wrapped != null) {
			return wrapped.listIterator(index);
		}
		return Collections.EMPTY_LIST.listIterator();
	}

	@Override
	public boolean remove(Object o) {
		if (wrapped != null) {
			return wrapped.remove(o);
		}
		return false;
	}

	@Override
	public E remove(int index) {
		if (wrapped != null) {
			return wrapped.remove(index);
		}
		return null;
	}

	@Override
	public boolean removeAll(Collection<?> c) {
		if (wrapped != null) {
			return wrapped.removeAll(c);
		}
		return false;
	}

	@Override
	public boolean retainAll(Collection<?> c) {
		if (wrapped != null) {
			return wrapped.retainAll(c);
		}
		return false;
	}

	/**
	 * If {@link #newList()} was used before, delegate to the wrapped list.
	 * 
	 * @throws UnsupportedOperationException if {@link #newList()} was not called before.
	 * 
	 * @see List#set(int, Object)
	 */
	@Override
	public E set(int index, E element) {
		if (wrapped != null) {
			return wrapped.set(index, element);
		}
		throw new UnsupportedOperationException();
	}

	@Override
	public int size() {
		if (wrapped != null) {
			return wrapped.size();
		}
		return 0;
	}

	@Override
	@SuppressWarnings("unchecked")
	public List<E> subList(int fromIndex, int toIndex) {
		if (wrapped != null) {
			return wrapped.subList(fromIndex, toIndex);
		}
		return Collections.EMPTY_LIST;
	}

	@Override
	public Object[] toArray() {
		if (wrapped != null) {
			return wrapped.toArray();
		}
		return Collections.EMPTY_LIST.toArray();
	}

	@Override
	public <T> T[] toArray(T[] a) {
		if (wrapped != null) {
			return wrapped.toArray(a);
		}
		return a;
	}

	@Override
	public String toString() {
		if (wrapped != null) {
			return wrapped.toString();
		}
		return Collections.EMPTY_LIST.toString();
	}

	@Override
	public boolean equals(Object obj) {
		if (wrapped != null) {
			return wrapped.equals(obj);
		}
		return super.equals(obj);
	}
}
