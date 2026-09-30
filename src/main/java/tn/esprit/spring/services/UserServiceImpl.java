package tn.esprit.spring.services;

import java.util.List;

import org.apache.logging.log4j.LogManager;
import org.apache.logging.log4j.Logger;
import org.springframework.beans.factory.annotation.Autowired;
import org.springframework.stereotype.Service;

import tn.esprit.spring.entities.User;
import tn.esprit.spring.repository.UserRepository;

@Service
public class UserServiceImpl implements IUserService {

	@Autowired
	UserRepository userRepository;

	private static final Logger l = LogManager.getLogger(UserServiceImpl.class);

	@Override
	public List<User> retrieveAllUsers() {
		l.info("In retrieveAllUsers()");
		List<User> users = userRepository.findAll();
		l.info("Out of retrieveAllUsers() : {} users", users.size());
		return users;
	}

	@Override
	public User addUser(User u) {

		User utilisateur = null;

		try {
			l.info("In addUser() : {}", u);
			utilisateur = userRepository.save(u);
			l.info("Out of addUser() : {}", utilisateur);

		} catch (Exception e) {
			l.error("error in addUser() : {}", e.getMessage());
		}

		return utilisateur;
	}

	@Override
	public User updateUser(User u) {

		User userUpdated = null;

		try {
			l.info("In updateUser() : {}", u);
			userUpdated = userRepository.save(u);
			l.info("Out of updateUser() : {}", userUpdated);

		} catch (Exception e) {
			l.error("error in updateUser() : {}", e.getMessage());
		}

		return userUpdated;
	}

	@Override
	public void deleteUser(String id) {

		try {
			l.info("In deleteUser() : id = {}", id);
			userRepository.deleteById(Long.parseLong(id));
			l.info("Out of deleteUser()");

		} catch (Exception e) {
			l.error("error in deleteUser() : {}", e.getMessage());
		}

	}

	@Override
	public User retrieveUser(String id) {
		User u = null;
		try {
			l.info("In retrieveUser() : id = {}", id);
			u = userRepository.findById(Long.parseLong(id)).orElse(null);
			l.info("Out of retrieveUser() : {}", u);

		} catch (Exception e) {
			l.error("error in retrieveUser() : {}", e.getMessage());
		}

		return u;
	}

}
