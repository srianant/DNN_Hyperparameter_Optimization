
import java.util.ArrayList;
import java.util.Arrays;
import java.util.List;

class Main {

	//----------------------------- Test -------------------------------------------// 
	public static void main(String[] args) {

		String s = "dabcba"; 

		Main test = new Main(); 
 
		System.out.println("Target string:\n=> " + s) ; 
		System.out.println("\nThe longest palindromic substring:\n=> "+test.longestPalindrome(s));

		System.out.println("\nAll possible palindrome partitioning:\n=> " + test.partition(s));
		System.out.println("\nMinimum cuts needed for a palindrome partitioning:\n=> " + test.minCut(s));

	} 

	//----------------- Methods for detecting alindrome ----------------------------// 
	/**
	 * Given a string S, find the longest palindromic substring in S. 
	 * Assume that the maximum length of S is 1000, 
	 * and there exists one unique longest palindromic substring.
	 * DP Solution
	 **/
	public String longestPalindrome(String s ){
		if(s == null || s.length() == 0) return ""; 
		// table[i][j] is true if substring str[i..j] is palindrome. 
		boolean[][] table = new boolean[s.length()][s.length()];
		int maxLen = 1, start = 0; 
		
		for(int i = 0; i < s.length(); i ++) table[i][i] = true; 	
		for(int i = 0; i < s.length() - 1; i ++){
			if(s.charAt(i) == s.charAt(i + 1)){
				table[i][i + 1] = true; 
				maxLen = 2; start = i; 
			}
		}
		for(int len = 3; len <= s.length(); len ++){
			for(int i = 0; i < s.length() - len + 1; i ++){ 
				int j = i + len - 1;  
				if(s.charAt(i) == s.charAt(j) && table[i + 1][j - 1]){ 
					table[i][j] = true; 
					maxLen = len; start = i; 
				}
			}
		}
		return s.substring(start, start + maxLen); 
	}


	/**
	 * Palindrome Partitioning I 
	 * Given a string s, partition s such that every substring of the partition is a palindrome.
	 * Return all possible palindrome partitioning of s.
	 * DP + recursion 
	 **/
	public List<List<String>> partition(String s ){
		List<List<String>> output = new ArrayList<>(); 
		List<String> list = new ArrayList<>(); 
		
		if(s == null || s.length() == 0) return output; 
		
		// build the DP table
		boolean[][] isPalindrome = new boolean[s.length()][s.length()]; 
		for(int len = 1; len <= s.length(); len++){
			for(int i  = 0; i < s.length() - len + 1; i++){
				int j = i + len - 1; 
				if(s.charAt(i) == s.charAt(j)){
					if(len == 1 || len == 2) isPalindrome[i][j] = true; 
					else isPalindrome[i][j] = isPalindrome[i + 1][j - 1]; 
				}
			}
		}
		partition(s, isPalindrome, 0, list, output); 
		return output; 
	}

	private void partition(String s, boolean[][] isPalindrome, int start, List<String> list, List<List<String>> output){
		if(start == s.length()){
			output.add(new ArrayList<>(list)); 
			return; 
		}
		
		for(int i = start; i < s.length(); i ++ ){
			if(isPalindrome[start][i]){
				list.add(s.substring(start, i + 1)); 
				partition(s, isPalindrome, i + 1, list, output); 
				list.remove(list.size() - 1); 
			}
		}
	}


	/**
	 * Palindrome Partitioning II 
	 * Given a string s, partition s such that every substring of the partition is a palindrome. 
	 * Return the minimum cuts needed for a palindrome partitioning of s.
	 **/
 	public int minCut(String s){
 		
 		if(s == null || s.length() < 2) return 0; 
 		
 		// build a table of palindromic substrings  
 		boolean[][] table = new boolean[s.length()][s.length()];
 		for(int len = 1; len <= s.length() ; len ++){
 			for(int i = 0; i < s.length() - len + 1; i++){
 				int j = i + len - 1; 
 				if(s.charAt(i) == s.charAt(j )){
 					if(len == 1 || len == 2) table[i][j] = true; 
 					else table[i][j] = table[i + 1][j - 1]; 
 				}
 			}
 		}
 		
 
 		// cuts[i]: the minimum cuts needed for s[i..length-1]  
 		int[] cuts = new int[s.length() + 1];
 		for(int i = 0; i <= s.length(); i ++) cuts[i] = s.length() - i - 1;

 		for(int i = s.length() - 1; i >= 0; i --){
 			for(int j = i; j < s.length(); j++){
 				if(table[i][j])cuts[i] = Math.min(cuts[i], cuts[j + 1] + 1); 
 			}
 		}

 		return cuts[0]; 
 	}
}
