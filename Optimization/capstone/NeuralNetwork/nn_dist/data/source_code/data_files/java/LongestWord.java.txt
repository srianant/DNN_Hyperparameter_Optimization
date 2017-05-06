import java.io.BufferedReader;
import java.io.File;
import java.io.FileInputStream;
import java.io.FileNotFoundException;
import java.io.IOException;
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;
import java.util.StringTokenizer;

import trieADT.Trie;


public class LongestWord{
	
	private static Trie trie = new Trie();
	
	public static void main(String[] args) {
		BufferedReader br = null;
		try {
			
			String[] sortedWords = null;
			String[] longestWords = null;
			List<String> wordArray = new ArrayList<String>();
			
			// Use command line to enter file name
			// Reading data from file
			
			if(args.length == 0)
			{
				System.out.println("Usage:  java LongestWords filename");
				return;
			}
			byte[] data = new byte[(int) new File(args[0]).length()];
			
			// Read data from the file into buffer and close the file
			FileInputStream file = new FileInputStream(args[0]);
			file.read(data);
			file.close();
	
			StringTokenizer tokens = new StringTokenizer(new String(data));		
			
			// Create an array list of tokens returned by StringTokenizer (actually our words)
			while(tokens.hasMoreTokens())
			{
				wordArray.add(tokens.nextToken());
			}
			
			// Print the number of words in the file
			System.out.println("Total number of words in file :   " +wordArray.size());
			
			// Convert array list to an array of string
			sortedWords = (String[])wordArray.toArray(new String[wordArray.size()]);
			// Sort the words based on length
			Arrays.sort(sortedWords, new StringLengthSort());
			
			// Populate trie ADT that we created
			for(String word : sortedWords)
			{
				trie.insert(word);
			}
			
			
			/* Algorithm Start */
			
			//start time
			long startTime = System.nanoTime();
			
			// Find all the words made of other words
			longestWords = LongestWordsContainingOtherWords(sortedWords);
			
			//Print the longest word and the number of words made of other words
			System.out.println("Longest Word made of other words:   "+ longestWords[0]);
			System.out.println("Total number of words that can be made of other words :   " +longestWords.length);
			
			// end time
			long endTime = System.nanoTime();
			
			//Print the time taken by the system for this program
			System.out.println("Took "+(endTime - startTime) + " ns");
			
			/* Algorithm End */
			
		} catch (FileNotFoundException e) {
			// TODO Auto-generated catch block
			System.out.println("Please enter a correct filename!");			
			//e.printStackTrace();
		} catch (IOException e) {
			// TODO Auto-generated catch block
			e.printStackTrace();
		}finally {
			try {
				if (br != null)
					br.close();
			} catch (IOException e) {
				e.printStackTrace();
			}
		}
	}
	
	public static String[] LongestWordsContainingOtherWords(String[] list)
	{
		List<String> wordList = new ArrayList<String>();
		for(String word: list)
		{
			//System.out.println(word);
			if(isRequiredWord(word,true))
			{
				wordList.add(word);
			}
		}
		
		// For debugging
//		for(int i=0;i<1;i++)
//		{
//			System.out.println(list[i]);
//			System.out.println(isRequiredWord(list[i],true));
//			
//				wordList.add(list[i]);
//			
//			
//		}
		 return( (String[])wordList.toArray(new String[wordList.size()]) );
	}
	
	public static boolean isRequiredWord(String word,boolean fullword)
	{
		// Remove the word so that the word is not matched to itself to find the longest word
		if (fullword)
		{
			trie.delete(word);
		}
		// Loop over the length of the word
		for(int i=0;i<word.length();i++)
		{
			//System.out.println(word.substring(0, i+1));
			if(trie.search(word.substring(0, i+1)))
			{
				if(i+1==word.length() || isRequiredWord(word.substring(i+1,word.length()),false) )
				{
					return true;
				}
			}
		}
		//System.out.println(false);
		if(fullword)
		{
			trie.insert(word);
		}
		return false;
	}
}
